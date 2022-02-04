local common = import 'common.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local sm =
  prom.ServiceMonitor('kyverno') {
    metadata+: {
      namespace: params.namespace,
      labels+: common.Labels,
    },
    spec: {
      endpoints: [ {
        port: 'metrics-port',
      } ],
      namespaceSelector: { matchNames: [ params.namespace ] },
      selector: {
        matchLabels: common.Labels,
      },
    },
  };

if params.monitoring.enabled then
  {
    '10_monitoring/00_servicemonitor-kyverno': sm,
  }
else
  {}
