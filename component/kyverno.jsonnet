// main template for kyverno
local common = import 'common.libsonnet';
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local manifests_path = 'kyverno/manifests/kyverno/' + params.manifest_version;

local cluster_roles = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterroles.yaml'));
local cluster_role_bindings = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterrolebindings.yaml'));
local roles = std.parseJson(kap.yaml_load_stream(manifests_path + '/roles.yaml'));
local role_bindings = std.parseJson(kap.yaml_load_stream(manifests_path + '/rolebindings.yaml'));
local service_account = std.parseJson(kap.yaml_load(manifests_path + '/serviceaccount.yaml'));

local services = std.parseJson(kap.yaml_load_stream(manifests_path + '/service.yaml'));
local deployment = std.parseJson(kap.yaml_load(manifests_path + '/deployment.yaml'));
local configmap = std.parseJson(kap.yaml_load(manifests_path + '/configmap.yaml'));
local metricsConfig = std.parseJson(kap.yaml_load(manifests_path + '/metricsconfigmap.yaml'));


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

local patchRoleBindings = function(bindings)
  std.map(
    function(role_binding)
      role_binding {
        subjects: std.map(
          function(subj) subj {
            namespace: params.namespace,
          },
          super.subjects
        ),
      },
    bindings
  );

local objects =
  [] +
  cluster_roles +
  patchRoleBindings(cluster_role_bindings) +
  roles +
  patchRoleBindings(role_bindings) +
  services +
  [
    service_account {},
    deployment {
      spec+: {
        replicas: params.replicas,
        template+: {
          spec+: nodeSelectorConfig(params.nodeSelectorRole) + {
            affinity: params.affinity,
            initContainers: [
              if c.name == 'kyverno-pre' then
                c {
                  image: '%s/%s:%s' % [ params.images.pre.registry, params.images.pre.repository, params.images.pre.version ],
                  resources: std.prune(super.resources + params.resources.pre),
                }
              else
                c
              for c in super.initContainers
            ],
            containers: [
              if c.name == 'kyverno' then
                c {
                  image: '%s/%s:%s' % [ params.images.kyverno.registry, params.images.kyverno.repository, params.images.kyverno.version ],
                  resources: std.prune(super.resources + params.resources.kyverno),
                  args: params.extraArgs,
                }
              else
                c
              for c in super.containers
            ],
          },
        },
      },
    },

    configmap {
      data: {
        resourceFilters: std.join('', std.prune(params.resourceFilters)),
        excludeGroupRole: std.join(',', std.prune(params.excludeGroupRole)),
        generateSuccessEvents: params.generateSuccessEvents,
      },
    },

    metricsConfig,

    kube.PodDisruptionBudget('kyverno') {
      spec+: {
        selector: deployment.spec.selector,
      } + params.podDisruptionBudget,
    },
  ]
;

{
  [std.asciiLower('02_%s-%s' % [ obj.kind, std.strReplace(obj.metadata.name, ':', '-') ])]: obj {
    metadata+: {
      namespace: params.namespace,
      labels+: common.Labels,
    },
  }
  for obj in objects
}
