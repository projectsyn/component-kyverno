local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local defaultLabels = {
  'app.kubernetes.io/name': 'kyverno',
  'app.kubernetes.io/component': 'kyverno',
  'app.kubernetes.io/managed-by': 'commodore',
};

local additionalClusterRoles = [
  kube.ClusterRole('kyverno:user:%s' % [ role ],) {
    metadata+: {
      labels+: defaultLabels,
    },
    rules: params.additionalClusterRoles[role],
  }
  for role in std.prune(std.objectFields(params.additionalClusterRoles))
];

local additionalRoleBindings = [
  kube.ClusterRoleBinding('kyverno:user:%s' % [ binding ],) {
    metadata+: {
      labels+: defaultLabels,
    },
    roleRef+: params.additionalRoleBindings[binding],
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'kyverno-service-account',
        namespace: params.namespace,
      },
    ],
  }
  for binding in std.prune(std.objectFields(params.additionalRoleBindings))
];

{
  '03_additional-clusterroles': additionalClusterRoles,
  '04_additional-rolebindings': additionalRoleBindings,
}
