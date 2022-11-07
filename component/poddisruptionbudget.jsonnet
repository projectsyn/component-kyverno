local common = import 'common.libsonnet';
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;


{
  '10_pod-disruption-budget': kube.PodDisruptionBudget('kyverno') {
    metadata+: {
      namespace: params.namespace,
      labels+: common.Labels,
    },
    spec+: params.podDisruptionBudget,
  },
}
