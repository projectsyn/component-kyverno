// main template for kyverno
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local manifests_path = 'kyverno/manifests/kyverno/' + params.manifest_version;

local roles = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterroles.yaml'));
local role_bindings = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterrolebindings.yaml'));
local service_account = std.parseJson(kap.yaml_load(manifests_path + '/serviceaccount.yaml'));

local services = std.parseJson(kap.yaml_load_stream(manifests_path + '/service.yaml'));
local deployment = std.parseJson(kap.yaml_load(manifests_path + '/deployment.yaml'));
local configmap = std.parseJson(kap.yaml_load(manifests_path + '/configmap.yaml'));

local objects = [] +
                roles +
                std.map(function(role_binding) role_binding {
                  subjects: std.map(function(subj) subj {
                    namespace: params.namespace,
                  }, super.subjects),
                }, role_bindings) +
                services +
                [
                  service_account {},
                  deployment {
                    spec+: {
                      replicas: params.replicas,
                      template+: {
                        spec+: {
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
                ]
;

{
  [std.asciiLower('02_%s-%s' % [ obj.kind, std.strReplace(obj.metadata.name, ':', '-') ])]: obj {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in objects
}
