/**
 * \file Helper to create Kyverno objects.
 */

local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.storageclass;

/**
  * \brief Helper to create Policy objects.
  *
  * \arg The name of the Policy.
  * \return A Policy object.
  */
local Policy(name) = kube._Object('kyverno.io/v1', 'Policy', name) {};


/**
  * \brief Helper to create ClusterPolicy objects.
  *
  * \arg The name of the ClusterPolicy.
  * \return A ClusterPolicy object.
  */
local ClusterPolicy(name) = kube._Object('kyverno.io/v1', 'ClusterPolicy', name) {};


/**
  * \brief Helper to create ReportChangeRequest objects.
  *
  * \arg The name of the ReportChangeRequest.
  * \return A ReportChangeRequest object.
  */
local ReportChangeRequest(name) = kube._Object('kyverno.io/v1alpha1', 'ReportChangeRequest', name) {};


/**
  * \brief Helper to create ClusterReportChangeRequest objects.
  *
  * \arg The name of the ClusterReportChangeRequest.
  * \return A ClusterReportChangeRequest object.
  */
local ClusterReportChangeRequest(name) = kube._Object('kyverno.io/v1alpha1', 'ClusterReportChangeRequest', name) {};

/**
  * \brief Helper to create GenerateRequest objects.
  *
  * \arg The name of the GenerateRequest.
  * \return A GenerateRequest object.
  */
local GenerateRequest(name) = kube._Object('kyverno.io/v1alpha1', 'GenerateRequest', name) {};

{
  Policy: Policy,
  ClusterPolicy: ClusterPolicy,
  ReportChangeRequest: ReportChangeRequest,
  ClusterReportChangeRequest: ClusterReportChangeRequest,
  GenerateRequest: GenerateRequest,
}
+
import 'kyverno-resource-locker.libsonnet'
