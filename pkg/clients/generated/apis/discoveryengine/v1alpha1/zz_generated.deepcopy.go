//go:build !ignore_autogenerated
// +build !ignore_autogenerated

// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// *** DISCLAIMER ***
// Config Connector's go-client for CRDs is currently in ALPHA, which means
// that future versions of the go-client may include breaking changes.
// Please try it out and give us feedback!

// Code generated by deepcopy-gen. DO NOT EDIT.

package v1alpha1

import (
	k8sv1alpha1 "github.com/GoogleCloudPlatform/k8s-config-connector/pkg/clients/generated/apis/k8s/v1alpha1"
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DatastoreBillingEstimationStatus) DeepCopyInto(out *DatastoreBillingEstimationStatus) {
	*out = *in
	if in.StructuredDataSize != nil {
		in, out := &in.StructuredDataSize, &out.StructuredDataSize
		*out = new(int64)
		**out = **in
	}
	if in.StructuredDataUpdateTime != nil {
		in, out := &in.StructuredDataUpdateTime, &out.StructuredDataUpdateTime
		*out = new(string)
		**out = **in
	}
	if in.UnstructuredDataSize != nil {
		in, out := &in.UnstructuredDataSize, &out.UnstructuredDataSize
		*out = new(int64)
		**out = **in
	}
	if in.UnstructuredDataUpdateTime != nil {
		in, out := &in.UnstructuredDataUpdateTime, &out.UnstructuredDataUpdateTime
		*out = new(string)
		**out = **in
	}
	if in.WebsiteDataSize != nil {
		in, out := &in.WebsiteDataSize, &out.WebsiteDataSize
		*out = new(int64)
		**out = **in
	}
	if in.WebsiteDataUpdateTime != nil {
		in, out := &in.WebsiteDataUpdateTime, &out.WebsiteDataUpdateTime
		*out = new(string)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DatastoreBillingEstimationStatus.
func (in *DatastoreBillingEstimationStatus) DeepCopy() *DatastoreBillingEstimationStatus {
	if in == nil {
		return nil
	}
	out := new(DatastoreBillingEstimationStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DatastoreObservedStateStatus) DeepCopyInto(out *DatastoreObservedStateStatus) {
	*out = *in
	if in.BillingEstimation != nil {
		in, out := &in.BillingEstimation, &out.BillingEstimation
		*out = new(DatastoreBillingEstimationStatus)
		(*in).DeepCopyInto(*out)
	}
	if in.CreateTime != nil {
		in, out := &in.CreateTime, &out.CreateTime
		*out = new(string)
		**out = **in
	}
	if in.DefaultSchemaID != nil {
		in, out := &in.DefaultSchemaID, &out.DefaultSchemaID
		*out = new(string)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DatastoreObservedStateStatus.
func (in *DatastoreObservedStateStatus) DeepCopy() *DatastoreObservedStateStatus {
	if in == nil {
		return nil
	}
	out := new(DatastoreObservedStateStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DatastoreWorkspaceConfig) DeepCopyInto(out *DatastoreWorkspaceConfig) {
	*out = *in
	if in.DasherCustomerID != nil {
		in, out := &in.DasherCustomerID, &out.DasherCustomerID
		*out = new(string)
		**out = **in
	}
	if in.SuperAdminEmailAddress != nil {
		in, out := &in.SuperAdminEmailAddress, &out.SuperAdminEmailAddress
		*out = new(string)
		**out = **in
	}
	if in.SuperAdminServiceAccount != nil {
		in, out := &in.SuperAdminServiceAccount, &out.SuperAdminServiceAccount
		*out = new(string)
		**out = **in
	}
	if in.Type != nil {
		in, out := &in.Type, &out.Type
		*out = new(string)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DatastoreWorkspaceConfig.
func (in *DatastoreWorkspaceConfig) DeepCopy() *DatastoreWorkspaceConfig {
	if in == nil {
		return nil
	}
	out := new(DatastoreWorkspaceConfig)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DiscoveryEngineDataStore) DeepCopyInto(out *DiscoveryEngineDataStore) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	in.Spec.DeepCopyInto(&out.Spec)
	in.Status.DeepCopyInto(&out.Status)
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DiscoveryEngineDataStore.
func (in *DiscoveryEngineDataStore) DeepCopy() *DiscoveryEngineDataStore {
	if in == nil {
		return nil
	}
	out := new(DiscoveryEngineDataStore)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *DiscoveryEngineDataStore) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DiscoveryEngineDataStoreList) DeepCopyInto(out *DiscoveryEngineDataStoreList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]DiscoveryEngineDataStore, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DiscoveryEngineDataStoreList.
func (in *DiscoveryEngineDataStoreList) DeepCopy() *DiscoveryEngineDataStoreList {
	if in == nil {
		return nil
	}
	out := new(DiscoveryEngineDataStoreList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *DiscoveryEngineDataStoreList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DiscoveryEngineDataStoreSpec) DeepCopyInto(out *DiscoveryEngineDataStoreSpec) {
	*out = *in
	if in.ContentConfig != nil {
		in, out := &in.ContentConfig, &out.ContentConfig
		*out = new(string)
		**out = **in
	}
	if in.DisplayName != nil {
		in, out := &in.DisplayName, &out.DisplayName
		*out = new(string)
		**out = **in
	}
	if in.IndustryVertical != nil {
		in, out := &in.IndustryVertical, &out.IndustryVertical
		*out = new(string)
		**out = **in
	}
	out.ProjectRef = in.ProjectRef
	if in.ResourceID != nil {
		in, out := &in.ResourceID, &out.ResourceID
		*out = new(string)
		**out = **in
	}
	if in.SolutionTypes != nil {
		in, out := &in.SolutionTypes, &out.SolutionTypes
		*out = make([]string, len(*in))
		copy(*out, *in)
	}
	if in.WorkspaceConfig != nil {
		in, out := &in.WorkspaceConfig, &out.WorkspaceConfig
		*out = new(DatastoreWorkspaceConfig)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DiscoveryEngineDataStoreSpec.
func (in *DiscoveryEngineDataStoreSpec) DeepCopy() *DiscoveryEngineDataStoreSpec {
	if in == nil {
		return nil
	}
	out := new(DiscoveryEngineDataStoreSpec)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *DiscoveryEngineDataStoreStatus) DeepCopyInto(out *DiscoveryEngineDataStoreStatus) {
	*out = *in
	if in.Conditions != nil {
		in, out := &in.Conditions, &out.Conditions
		*out = make([]k8sv1alpha1.Condition, len(*in))
		copy(*out, *in)
	}
	if in.ExternalRef != nil {
		in, out := &in.ExternalRef, &out.ExternalRef
		*out = new(string)
		**out = **in
	}
	if in.ObservedGeneration != nil {
		in, out := &in.ObservedGeneration, &out.ObservedGeneration
		*out = new(int64)
		**out = **in
	}
	if in.ObservedState != nil {
		in, out := &in.ObservedState, &out.ObservedState
		*out = new(DatastoreObservedStateStatus)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new DiscoveryEngineDataStoreStatus.
func (in *DiscoveryEngineDataStoreStatus) DeepCopy() *DiscoveryEngineDataStoreStatus {
	if in == nil {
		return nil
	}
	out := new(DiscoveryEngineDataStoreStatus)
	in.DeepCopyInto(out)
	return out
}
