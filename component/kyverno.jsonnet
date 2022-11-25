// Template to render kustomization overlay
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';

local kube = import 'lib/kube.libjsonnet';

local common = import 'common.libsonnet';

local inv = kap.inventory();
local params = inv.parameters.kyverno;

local nodeSelectorConfig(role) =
  if role == null then
    {}
  else
    local label = 'node-role.kubernetes.io/%s' % role;
    {
      nodeSelector+: {
        [label]: '',
      },
      tolerations+: [ {
        key: label,
        operator: 'Exists',
        effect: 'NoSchedule',
      } ],
    };

local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

local monitoringLabel =
  if isOpenshift then
    {
      'openshift.io/cluster-monitoring': 'true',
    }
  else
    {
      SYNMonitoring: 'main',
    };

local nodeSelectionNamespaceAnnotations = if params.nodeSelectorRole != null then
  {
    'openshift.io/node-selector': 'node-role.kubernetes.io/%s=' % params.nodeSelectorRole,
  }
else
  {};

com.Kustomization(
  params.kustomization_url,
  params.manifest_version,
  {
    'ghcr.io/kyverno/kyverno': {
      newTag: params.images.kyverno.version,
      newName: '%(registry)s/%(repository)s' % params.images.kyverno,
    },
    'ghcr.io/kyverno/kyvernopre': {
      newTag: params.images.pre.version,
      newName: '%(registry)s/%(repository)s' % params.images.pre,
    },
  },
  {
    namespace: params.namespace,
    replicas: [
      {
        name: 'kyverno',
        count: params.replicas,
      },
    ],
    transformers: [
      'labels.yaml',
      'crdAnnotations.yaml',
    ],
    patchesStrategicMerge: [
      'deployment.yaml',
      'namespace.yaml',
    ],
  },
) {
  deployment: kube.Deployment('kyverno') {
    spec: {
      template: {
        spec:
          nodeSelectorConfig(params.nodeSelectorRole)
          +
          {
            affinity: params.affinity,
          }
          {
            initContainers: [
              {
                name: 'kyverno-pre',
                resources: params.resources.pre,
                securityContext: params.containerSecurityContext,
                imagePullPolicy: null,
              },
            ],
            containers: [
              {
                name: 'kyverno',
                resources: params.resources.kyverno,
                args: params.extraArgs,
                securityContext: params.containerSecurityContext,
                imagePullPolicy: null,
              },
            ],
          },
      },
    },
  },
  // We need to patch namespace "kyverno" as the namespace renaming is only applied after doing strategic merge patches
  namespace: kube.Namespace('kyverno') {
    metadata+: {
      labels+: common.Labels + monitoringLabel {
        'network-policies.syn.tools/purge-defaults': 'true',
        'network-policies.syn.tools/no-defaults': 'true',
        name: params.namespace,
      },
      annotations+: nodeSelectionNamespaceAnnotations,
    },
  },
  labels: {
    apiVersion: 'builtin',
    kind: 'LabelTransformer',
    metadata: {
      name: 'labelTransformer',
    },
    labels: {
      'app.kubernetes.io/version': params.manifest_version,
    },
    fieldSpecs: [
      {
        path: 'metadata/labels',
        create: true,
      },
      {
        kind: 'Deployment',
        path: 'spec/template/metadata/labels',
        create: true,
      },
    ],
  },
  crdAnnotations: {
    apiVersion: 'builtin',
    kind: 'AnnotationsTransformer',
    metadata: {
      name: 'crdAnnotationsTransformer',
    },
    annotations: {
      // Use replace for CRDs to avoid errors because the
      // last-applied-configuration annotation gets too big.
      'argocd.argoproj.io/sync-options': 'Replace=true',
    },
    fieldSpecs: [
      {
        kind: 'CustomResourceDefinition',
        path: 'metadata/annotations',
        create: true,
      },
    ],
  },
}
