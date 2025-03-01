// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ----------------------------------------------------------------------------
//
//     ***     AUTO GENERATED CODE    ***    AUTO GENERATED CODE     ***
//
// ----------------------------------------------------------------------------
//
//     This file is automatically generated by Config Connector and manual
//     changes will be clobbered when the file is regenerated.
//
// ----------------------------------------------------------------------------

// *** DISCLAIMER ***
// Config Connector's go-client for CRDs is currently in ALPHA, which means
// that future versions of the go-client may include breaking changes.
// Please try it out and give us feedback!

package v1alpha1

import (
	"github.com/GoogleCloudPlatform/k8s-config-connector/pkg/clients/generated/apis/k8s/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type DatastoreWorkspaceConfig struct {
	/* Obfuscated Dasher customer ID. */
	// +optional
	DasherCustomerID *string `json:"dasherCustomerID,omitempty"`

	/* Optional. The super admin email address for the workspace that will be used for access token generation. For now we only use it for Native Google Drive connector data ingestion. */
	// +optional
	SuperAdminEmailAddress *string `json:"superAdminEmailAddress,omitempty"`

	/* Optional. The super admin service account for the workspace that will be used for access token generation. For now we only use it for Native Google Drive connector data ingestion. */
	// +optional
	SuperAdminServiceAccount *string `json:"superAdminServiceAccount,omitempty"`

	/* The Google Workspace data source. */
	// +optional
	Type *string `json:"type,omitempty"`
}

type DiscoveryEngineDataStoreSpec struct {
	/* Immutable. The collection for the DataStore. */
	Collection string `json:"collection"`

	/* Immutable. The content config of the data store. If this field is unset, the server behavior defaults to [ContentConfig.NO_CONTENT][google.cloud.discoveryengine.v1.DataStore.ContentConfig.NO_CONTENT]. */
	// +optional
	ContentConfig *string `json:"contentConfig,omitempty"`

	/* Required. The data store display name.

	This field must be a UTF-8 encoded string with a length limit of 128
	characters. Otherwise, an INVALID_ARGUMENT error is returned. */
	// +optional
	DisplayName *string `json:"displayName,omitempty"`

	/* Immutable. The industry vertical that the data store registers. */
	// +optional
	IndustryVertical *string `json:"industryVertical,omitempty"`

	/* Immutable. The location for the resource. */
	Location string `json:"location"`

	/* The ID of the project in which the resource belongs. */
	ProjectRef v1alpha1.ResourceRef `json:"projectRef"`

	/* Immutable. The DiscoveryEngineDataStore name. If not given, the metadata.name will be used. */
	// +optional
	ResourceID *string `json:"resourceID,omitempty"`

	/* The solutions that the data store enrolls. Available solutions for each
	[industry_vertical][google.cloud.discoveryengine.v1.DataStore.industry_vertical]:

	* `MEDIA`: `SOLUTION_TYPE_RECOMMENDATION` and `SOLUTION_TYPE_SEARCH`.
	* `SITE_SEARCH`: `SOLUTION_TYPE_SEARCH` is automatically enrolled. Other
	solutions cannot be enrolled. */
	// +optional
	SolutionTypes []string `json:"solutionTypes,omitempty"`

	/* Config to store data store type configuration for workspace data. This must be set when [DataStore.content_config][google.cloud.discoveryengine.v1.DataStore.content_config] is set as [DataStore.ContentConfig.GOOGLE_WORKSPACE][google.cloud.discoveryengine.v1.DataStore.ContentConfig.GOOGLE_WORKSPACE]. */
	// +optional
	WorkspaceConfig *DatastoreWorkspaceConfig `json:"workspaceConfig,omitempty"`
}

type DatastoreBillingEstimationStatus struct {
	/* Data size for structured data in terms of bytes. */
	// +optional
	StructuredDataSize *int64 `json:"structuredDataSize,omitempty"`

	/* Last updated timestamp for structured data. */
	// +optional
	StructuredDataUpdateTime *string `json:"structuredDataUpdateTime,omitempty"`

	/* Data size for unstructured data in terms of bytes. */
	// +optional
	UnstructuredDataSize *int64 `json:"unstructuredDataSize,omitempty"`

	/* Last updated timestamp for unstructured data. */
	// +optional
	UnstructuredDataUpdateTime *string `json:"unstructuredDataUpdateTime,omitempty"`

	/* Data size for websites in terms of bytes. */
	// +optional
	WebsiteDataSize *int64 `json:"websiteDataSize,omitempty"`

	/* Last updated timestamp for websites. */
	// +optional
	WebsiteDataUpdateTime *string `json:"websiteDataUpdateTime,omitempty"`
}

type DatastoreObservedStateStatus struct {
	/* Output only. Data size estimation for billing. */
	// +optional
	BillingEstimation *DatastoreBillingEstimationStatus `json:"billingEstimation,omitempty"`

	/* Output only. Timestamp the [DataStore][google.cloud.discoveryengine.v1.DataStore] was created at. */
	// +optional
	CreateTime *string `json:"createTime,omitempty"`

	/* Output only. The id of the default [Schema][google.cloud.discoveryengine.v1.Schema] associated to this data store. */
	// +optional
	DefaultSchemaID *string `json:"defaultSchemaID,omitempty"`
}

type DiscoveryEngineDataStoreStatus struct {
	/* Conditions represent the latest available observations of the
	   DiscoveryEngineDataStore's current state. */
	Conditions []v1alpha1.Condition `json:"conditions,omitempty"`
	/* A unique specifier for the DiscoveryEngineDataStore resource in GCP. */
	// +optional
	ExternalRef *string `json:"externalRef,omitempty"`

	/* ObservedGeneration is the generation of the resource that was most recently observed by the Config Connector controller. If this is equal to metadata.generation, then that means that the current reported status reflects the most recent desired state of the resource. */
	// +optional
	ObservedGeneration *int64 `json:"observedGeneration,omitempty"`

	/* ObservedState is the state of the resource as most recently observed in GCP. */
	// +optional
	ObservedState *DatastoreObservedStateStatus `json:"observedState,omitempty"`
}

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +kubebuilder:resource:categories=gcp,shortName=gcpdiscoveryenginedatastore;gcpdiscoveryenginedatastores
// +kubebuilder:subresource:status
// +kubebuilder:metadata:labels="cnrm.cloud.google.com/managed-by-kcc=true";"cnrm.cloud.google.com/system=true"
// +kubebuilder:printcolumn:name="Age",JSONPath=".metadata.creationTimestamp",type="date"
// +kubebuilder:printcolumn:name="Ready",JSONPath=".status.conditions[?(@.type=='Ready')].status",type="string",description="When 'True', the most recent reconcile of the resource succeeded"
// +kubebuilder:printcolumn:name="Status",JSONPath=".status.conditions[?(@.type=='Ready')].reason",type="string",description="The reason for the value in 'Ready'"
// +kubebuilder:printcolumn:name="Status Age",JSONPath=".status.conditions[?(@.type=='Ready')].lastTransitionTime",type="date",description="The last transition time for the value in 'Status'"

// DiscoveryEngineDataStore is the Schema for the discoveryengine API
// +k8s:openapi-gen=true
type DiscoveryEngineDataStore struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   DiscoveryEngineDataStoreSpec   `json:"spec,omitempty"`
	Status DiscoveryEngineDataStoreStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// DiscoveryEngineDataStoreList contains a list of DiscoveryEngineDataStore
type DiscoveryEngineDataStoreList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []DiscoveryEngineDataStore `json:"items"`
}

func init() {
	SchemeBuilder.Register(&DiscoveryEngineDataStore{}, &DiscoveryEngineDataStoreList{})
}
