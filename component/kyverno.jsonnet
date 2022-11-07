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
  {},
  {
    namespace: params.namespace,
    replicas: [
      {
        name: 'kyverno',
        count: params.replicas,
      },
    ],
    patchesStrategicMerge: [
      'deployment.yaml',
      'namespace.yaml',
    ],
  },
) {
  // We need to patch namespace "kyverno" as the namespace renaming is only applied after doing strategic merge patches
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
              },
            ],
            containers: [
              {
                name: 'kyverno',
                resources: params.resources.kyverno,
                args: params.extraArgs,
              },
            ],
          },
      },
    },
  },
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
}
