local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local inv = kap.inventory();
local params = inv.parameters.kyverno;

local alertlabels = {
  syn: 'true',
  syn_component: 'kyverno',
};

local alerts = params.alerts;

local prometheusRule =
  com.namespaced(params.namespace, kube._Object('monitoring.coreos.com/v1', 'PrometheusRule', 'kyverno-alerts') {
    spec+: {
      groups+: [
        {
          name: 'kyverno-alerts',
          rules:
            std.sort(std.filterMap(
              function(field) alerts[field].enabled == true,
              function(field) alerts[field].rule {
                alert: field,
                labels+: alertlabels,
              },
              std.objectFields(alerts)
            )),
        },
      ],
    },
  });

{
  PrometheusRule: prometheusRule,
}
