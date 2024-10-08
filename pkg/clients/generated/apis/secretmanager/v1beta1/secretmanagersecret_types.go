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

package v1beta1

import (
	"github.com/GoogleCloudPlatform/k8s-config-connector/pkg/clients/generated/apis/k8s/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type SecretAuto struct {
	/* Optional. The customer-managed encryption configuration of the
	[Secret][google.cloud.secretmanager.v1.Secret]. If no configuration is
	provided, Google-managed default encryption is used.

	Updates to the [Secret][google.cloud.secretmanager.v1.Secret] encryption
	configuration only apply to
	[SecretVersions][google.cloud.secretmanager.v1.SecretVersion] added
	afterwards. They do not apply retroactively to existing
	[SecretVersions][google.cloud.secretmanager.v1.SecretVersion]. */
	// +optional
	CustomerManagedEncryption *SecretCustomerManagedEncryption `json:"customerManagedEncryption,omitempty"`
}

type SecretCustomerManagedEncryption struct {
	/* Required. The resource name of the Cloud KMS CryptoKey used to encrypt
	secret payloads.

	For secrets using the
	[UserManaged][google.cloud.secretmanager.v1.Replication.UserManaged]
	replication policy type, Cloud KMS CryptoKeys must reside in the same
	location as the [replica location][Secret.UserManaged.Replica.location].

	For secrets using the
	[Automatic][google.cloud.secretmanager.v1.Replication.Automatic]
	replication policy type, Cloud KMS CryptoKeys must reside in `global`.

	The expected format is `projects/* /locations/* /keyRings/* /cryptoKeys/*`. */
	KmsKeyRef v1alpha1.ResourceRef `json:"kmsKeyRef"`
}

type SecretReplicas struct {
	/* Optional. The customer-managed encryption configuration of the
	[User-Managed Replica][Replication.UserManaged.Replica]. If no
	configuration is provided, Google-managed default encryption is used.

	Updates to the [Secret][google.cloud.secretmanager.v1.Secret]
	encryption configuration only apply to
	[SecretVersions][google.cloud.secretmanager.v1.SecretVersion] added
	afterwards. They do not apply retroactively to existing
	[SecretVersions][google.cloud.secretmanager.v1.SecretVersion]. */
	// +optional
	CustomerManagedEncryption *SecretCustomerManagedEncryption `json:"customerManagedEncryption,omitempty"`

	/* The canonical IDs of the location to replicate data. For example: `"us-east1"`. */
	Location string `json:"location"`
}

type SecretReplication struct {
	/* The [Secret][google.cloud.secretmanager.v1.Secret] will automatically be replicated without any restrictions. */
	// +optional
	Auto *SecretAuto `json:"auto,omitempty"`

	/* The Secret will automatically be replicated without any restrictions. */
	// +optional
	Automatic *bool `json:"automatic,omitempty"`

	/* The [Secret][google.cloud.secretmanager.v1.Secret] will only be replicated into the locations specified. */
	// +optional
	UserManaged *SecretUserManaged `json:"userManaged,omitempty"`
}

type SecretRotation struct {
	/* Optional. Timestamp in UTC at which the
	[Secret][google.cloud.secretmanager.v1.Secret] is scheduled to rotate.
	Cannot be set to less than 300s (5 min) in the future and at most
	3153600000s (100 years).

	[next_rotation_time][google.cloud.secretmanager.v1.Rotation.next_rotation_time]
	MUST  be set if
	[rotation_period][google.cloud.secretmanager.v1.Rotation.rotation_period]
	is set. */
	// +optional
	NextRotationTime *string `json:"nextRotationTime,omitempty"`

	/* Input only. The Duration between rotation notifications. Must be in seconds
	and at least 3600s (1h) and at most 3153600000s (100 years).

	If
	[rotation_period][google.cloud.secretmanager.v1.Rotation.rotation_period]
	is set,
	[next_rotation_time][google.cloud.secretmanager.v1.Rotation.next_rotation_time]
	must be set.
	[next_rotation_time][google.cloud.secretmanager.v1.Rotation.next_rotation_time]
	will be advanced by this period when the service automatically sends
	rotation notifications. */
	// +optional
	RotationPeriod *string `json:"rotationPeriod,omitempty"`
}

type SecretTopics struct {
	TopicRef v1alpha1.ResourceRef `json:"topicRef"`
}

type SecretUserManaged struct {
	/* Required. The list of Replicas for this
	[Secret][google.cloud.secretmanager.v1.Secret].

	Cannot be empty. */
	Replicas []SecretReplicas `json:"replicas"`
}

type SecretManagerSecretSpec struct {
	/* Optional. Custom metadata about the secret.

	Annotations are distinct from various forms of labels.
	Annotations exist to allow client tools to store their own state
	information without requiring a database.

	Annotation keys must be between 1 and 63 characters long, have a UTF-8
	encoding of maximum 128 bytes, begin and end with an alphanumeric character
	([a-z0-9A-Z]), and may have dashes (-), underscores (_), dots (.), and
	alphanumerics in between these symbols.

	The total size of annotation keys and values must be less than 16KiB. */
	// +optional
	Annotations map[string]string `json:"annotations,omitempty"`

	/* Optional. Timestamp in UTC when the [Secret][google.cloud.secretmanager.v1.Secret] is scheduled to expire. This is always provided on output, regardless of what was sent on input. */
	// +optional
	ExpireTime *string `json:"expireTime,omitempty"`

	/* Optional. Immutable. The replication policy of the secret data attached to
	the [Secret][google.cloud.secretmanager.v1.Secret].

	The replication policy cannot be changed after the Secret has been created. */
	// +optional
	Replication *SecretReplication `json:"replication,omitempty"`

	/* Immutable. The SecretManagerSecret name. If not given, the metadata.name will be used. */
	// +optional
	ResourceID *string `json:"resourceID,omitempty"`

	/* Optional. Rotation policy attached to the [Secret][google.cloud.secretmanager.v1.Secret]. May be excluded if there is no rotation policy. */
	// +optional
	Rotation *SecretRotation `json:"rotation,omitempty"`

	/* Optional. A list of up to 10 Pub/Sub topics to which messages are published when control plane operations are called on the secret or its versions. */
	// +optional
	Topics []SecretTopics `json:"topics,omitempty"`

	/* Input only. The TTL for the [Secret][google.cloud.secretmanager.v1.Secret]. */
	// +optional
	Ttl *string `json:"ttl,omitempty"`

	/* Optional. Mapping from version alias to version name.

	A version alias is a string with a maximum length of 63 characters and can
	contain uppercase and lowercase letters, numerals, and the hyphen (`-`)
	and underscore ('_') characters. An alias string must start with a
	letter and cannot be the string 'latest' or 'NEW'.
	No more than 50 aliases can be assigned to a given secret.

	Version-Alias pairs will be viewable via GetSecret and modifiable via
	UpdateSecret. Access by alias is only be supported on
	GetSecretVersion and AccessSecretVersion. */
	// +optional
	VersionAliases map[string]string `json:"versionAliases,omitempty"`
}

type SecretObservedStateStatus struct {
}

type SecretManagerSecretStatus struct {
	/* Conditions represent the latest available observations of the
	   SecretManagerSecret's current state. */
	Conditions []v1alpha1.Condition `json:"conditions,omitempty"`
	/* A unique specifier for the SecretManagerSecret resource in GCP. */
	// +optional
	ExternalRef *string `json:"externalRef,omitempty"`

	/* [DEPRECATED] Please read from `.status.externalRef` instead. Config Connector will remove the `.status.name` in v1 Version. */
	// +optional
	Name *string `json:"name,omitempty"`

	/* ObservedGeneration is the generation of the resource that was most recently observed by the Config Connector controller. If this is equal to metadata.generation, then that means that the current reported status reflects the most recent desired state of the resource. */
	// +optional
	ObservedGeneration *int64 `json:"observedGeneration,omitempty"`

	/* ObservedState is the state of the resource as most recently observed in GCP. */
	// +optional
	ObservedState *SecretObservedStateStatus `json:"observedState,omitempty"`
}

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +kubebuilder:resource:categories=gcp,shortName=gcpsecretmanagersecret;gcpsecretmanagersecrets
// +kubebuilder:subresource:status
// +kubebuilder:metadata:labels="cnrm.cloud.google.com/managed-by-kcc=true";"cnrm.cloud.google.com/stability-level=stable";"cnrm.cloud.google.com/system=true";"cnrm.cloud.google.com/tf2crd=true"
// +kubebuilder:printcolumn:name="Age",JSONPath=".metadata.creationTimestamp",type="date"
// +kubebuilder:printcolumn:name="Ready",JSONPath=".status.conditions[?(@.type=='Ready')].status",type="string",description="When 'True', the most recent reconcile of the resource succeeded"
// +kubebuilder:printcolumn:name="Status",JSONPath=".status.conditions[?(@.type=='Ready')].reason",type="string",description="The reason for the value in 'Ready'"
// +kubebuilder:printcolumn:name="Status Age",JSONPath=".status.conditions[?(@.type=='Ready')].lastTransitionTime",type="date",description="The last transition time for the value in 'Status'"

// SecretManagerSecret is the Schema for the secretmanager API
// +k8s:openapi-gen=true
type SecretManagerSecret struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   SecretManagerSecretSpec   `json:"spec,omitempty"`
	Status SecretManagerSecretStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// SecretManagerSecretList contains a list of SecretManagerSecret
type SecretManagerSecretList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []SecretManagerSecret `json:"items"`
}

func init() {
	SchemeBuilder.Register(&SecretManagerSecret{}, &SecretManagerSecretList{})
}
