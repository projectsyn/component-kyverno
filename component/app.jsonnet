local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kyverno;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('kyverno', params.namespace);

{
  kyverno: app,
}
