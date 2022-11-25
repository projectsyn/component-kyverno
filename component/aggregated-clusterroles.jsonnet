local kube = import 'lib/kube.libjsonnet';

local namespaced_kyverno_kinds = [
  'policies',
  'admissionreports',
  'backgroundscanreports',
  'generaterequests',
  'updaterequests',
];
local cluster_kyverno_kinds = [
  'clusterpolicies',
  'clusteradmissionreports',
  'clusterbackgroundscanreports',
];
local namespaced_wgpolicy_kinds = [
  'policyreports',
];
local cluster_wgpolicy_kinds = [
  'clusterpolicyreports',
];


local readonly_verbs = [ 'get', 'list', 'watch' ];

{
  rbac_aggregate_to_view:
    kube.ClusterRole('syn-kyverno:aggregate-to-view') {
      metadata+: {
        labels+: {
          'rbac.authorization.k8s.io/aggregate-to-view': 'true',
        },
      },
      rules: [
        {
          apiGroups: [ 'kyverno.io' ],
          resources: namespaced_kyverno_kinds,
          verbs: readonly_verbs,
        },
        {
          apiGroups: [ 'wgpolicy.k8s.io' ],
          resources: namespaced_wgpolicy_kinds,
          verbs: readonly_verbs,
        },
      ],
    },
  rbac_aggregate_to_cluster_reader:
    kube.ClusterRole('syn-kyverno:aggregate-to-cluster-reader') {
      metadata+: {
        labels+: {
          'rbac.authorization.k8s.io/aggregate-to-cluster-reader': 'true',
        },
      },
      rules: [
        {
          apiGroups: [ 'kyverno.io' ],
          resources: cluster_kyverno_kinds,
          verbs: readonly_verbs,
        },
        {
          apiGroups: [ 'wgpolicy.k8s.io' ],
          resources: cluster_wgpolicy_kinds,
          verbs: readonly_verbs,
        },
      ],
    },
}
