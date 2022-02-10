local common = import 'common.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.kyverno;

local alertlabels = {
  syn: 'true',
  syn_component: 'kyverno',
};

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

local alerts = params.monitoring.alerts;
local prometheusRule =
  kube._Object('monitoring.coreos.com/v1', 'PrometheusRule', 'kyverno-alerts') {
    metadata+: {
      namespace: params.namespace,
      labels+: common.Labels,
    },
    spec+: {
      groups+: [
        {
          name: 'kyverno-alerts',
          rules:
            std.filterMap(
              function(field) alerts[field].enabled == true,
              function(field) alerts[field].rule {
                alert: field,
                labels+: alertlabels,
              },
              std.sort(std.objectFields(alerts)),
            ),
        },
      ],
    },
  };

if params.monitoring.enabled then
  {
    '10_monitoring/00_servicemonitor-kyverno': sm,
    '10_monitoring/10_prometheusrule_kyverno-alerts': prometheusRule,
  }
else
  {}
