local kube = import 'lib/kube.libjsonnet';
local rl = import 'lib/kyverno-resource-locker.libsonnet';


rl.Patch(
  kube.Deployment('test') {
    metadata+: {
      namespace: 'foo',
    },
  },
  {
    spec: {
      replicas: 5,
    },
  }
)
