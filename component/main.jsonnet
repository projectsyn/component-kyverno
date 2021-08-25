// main template for kyverno
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

{
  '01_namespace': kube.Namespace(params.namespace) {
    metadata+: {
      labels+: {
        'network-policies.syn.tools/purge-defaults': 'true',
        'network-policies.syn.tools/no-defaults': 'true',
      },
    },
  },
}
