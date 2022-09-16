local kyverno = import '../lib/kyverno.libsonnet';
local common = import 'common.libsonnet';
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.kyverno;

local clusterpolicies = com.generateResources(
  params.clusterpolicies,
  function(name) kyverno.ClusterPolicy(name) {
    metadata+: {
      labels+: common.Labels,
    },
  },
);


{
  [if std.length(clusterpolicies) > 0 then '80_policies']: clusterpolicies,
}
