// main template for kyverno
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local manifests_path = 'kyverno/manifests/kyverno/' + params.kyverno.manifest_version;

local roles = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterroles.yaml'));
local role_bindings = std.parseJson(kap.yaml_load_stream(manifests_path + '/clusterrolebindings.yaml'));
local services = std.parseJson(kap.yaml_load_stream(manifests_path + '/service.yaml'));
local service_account = std.parseJson(kap.yaml_load(manifests_path + '/serviceaccount.yaml'));
local deployment = std.parseJson(kap.yaml_load(manifests_path + '/deployment.yaml'));

local objects = [] +
                std.map(function(role) role {}, roles) +
                std.map(function(role_binding) role_binding {}, role_bindings) +
                std.map(function(service) service {}, services) +
                [ service_account {}, deployment {} ]
;

{
  [std.asciiLower("02_%s-%s" % [obj.kind, obj.metadata.name])]: obj {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in objects
}
