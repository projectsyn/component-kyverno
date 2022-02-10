// main template for kyverno
local alerts = import 'alerts.libsonnet';
local common = import 'common.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

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

{
  '01_namespace': kube.Namespace(params.namespace) {
    metadata+: {
      labels+: common.Labels + monitoringLabel {
        'network-policies.syn.tools/purge-defaults': 'true',
        'network-policies.syn.tools/no-defaults': 'true',
      },
      annotations+: nodeSelectionNamespaceAnnotations,
    },
  },
}
