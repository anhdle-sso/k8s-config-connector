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

package v1beta1

import (
	v1alpha1 "github.com/GoogleCloudPlatform/k8s-config-connector/pkg/clients/generated/apis/k8s/v1alpha1"
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretAuto) DeepCopyInto(out *SecretAuto) {
	*out = *in
	if in.CustomerManagedEncryption != nil {
		in, out := &in.CustomerManagedEncryption, &out.CustomerManagedEncryption
		*out = new(SecretCustomerManagedEncryption)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretAuto.
func (in *SecretAuto) DeepCopy() *SecretAuto {
	if in == nil {
		return nil
	}
	out := new(SecretAuto)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretCustomerManagedEncryption) DeepCopyInto(out *SecretCustomerManagedEncryption) {
	*out = *in
	out.KmsKeyRef = in.KmsKeyRef
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretCustomerManagedEncryption.
func (in *SecretCustomerManagedEncryption) DeepCopy() *SecretCustomerManagedEncryption {
	if in == nil {
		return nil
	}
	out := new(SecretCustomerManagedEncryption)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecret) DeepCopyInto(out *SecretManagerSecret) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	in.Spec.DeepCopyInto(&out.Spec)
	in.Status.DeepCopyInto(&out.Status)
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecret.
func (in *SecretManagerSecret) DeepCopy() *SecretManagerSecret {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecret)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *SecretManagerSecret) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretList) DeepCopyInto(out *SecretManagerSecretList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]SecretManagerSecret, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretList.
func (in *SecretManagerSecretList) DeepCopy() *SecretManagerSecretList {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *SecretManagerSecretList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretSpec) DeepCopyInto(out *SecretManagerSecretSpec) {
	*out = *in
	if in.Annotations != nil {
		in, out := &in.Annotations, &out.Annotations
		*out = make(map[string]string, len(*in))
		for key, val := range *in {
			(*out)[key] = val
		}
	}
	if in.ExpireTime != nil {
		in, out := &in.ExpireTime, &out.ExpireTime
		*out = new(string)
		**out = **in
	}
	if in.Replication != nil {
		in, out := &in.Replication, &out.Replication
		*out = new(SecretReplication)
		(*in).DeepCopyInto(*out)
	}
	if in.ResourceID != nil {
		in, out := &in.ResourceID, &out.ResourceID
		*out = new(string)
		**out = **in
	}
	if in.Rotation != nil {
		in, out := &in.Rotation, &out.Rotation
		*out = new(SecretRotation)
		(*in).DeepCopyInto(*out)
	}
	if in.Topics != nil {
		in, out := &in.Topics, &out.Topics
		*out = make([]SecretTopics, len(*in))
		copy(*out, *in)
	}
	if in.Ttl != nil {
		in, out := &in.Ttl, &out.Ttl
		*out = new(string)
		**out = **in
	}
	if in.VersionAliases != nil {
		in, out := &in.VersionAliases, &out.VersionAliases
		*out = make(map[string]string, len(*in))
		for key, val := range *in {
			(*out)[key] = val
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretSpec.
func (in *SecretManagerSecretSpec) DeepCopy() *SecretManagerSecretSpec {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretSpec)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretStatus) DeepCopyInto(out *SecretManagerSecretStatus) {
	*out = *in
	if in.Conditions != nil {
		in, out := &in.Conditions, &out.Conditions
		*out = make([]v1alpha1.Condition, len(*in))
		copy(*out, *in)
	}
	if in.ExternalRef != nil {
		in, out := &in.ExternalRef, &out.ExternalRef
		*out = new(string)
		**out = **in
	}
	if in.Name != nil {
		in, out := &in.Name, &out.Name
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
		*out = new(SecretObservedStateStatus)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretStatus.
func (in *SecretManagerSecretStatus) DeepCopy() *SecretManagerSecretStatus {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretVersion) DeepCopyInto(out *SecretManagerSecretVersion) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	in.Spec.DeepCopyInto(&out.Spec)
	in.Status.DeepCopyInto(&out.Status)
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretVersion.
func (in *SecretManagerSecretVersion) DeepCopy() *SecretManagerSecretVersion {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretVersion)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *SecretManagerSecretVersion) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretVersionList) DeepCopyInto(out *SecretManagerSecretVersionList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]SecretManagerSecretVersion, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretVersionList.
func (in *SecretManagerSecretVersionList) DeepCopy() *SecretManagerSecretVersionList {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretVersionList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *SecretManagerSecretVersionList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretVersionSpec) DeepCopyInto(out *SecretManagerSecretVersionSpec) {
	*out = *in
	if in.DeletionPolicy != nil {
		in, out := &in.DeletionPolicy, &out.DeletionPolicy
		*out = new(string)
		**out = **in
	}
	if in.Enabled != nil {
		in, out := &in.Enabled, &out.Enabled
		*out = new(bool)
		**out = **in
	}
	if in.IsSecretDataBase64 != nil {
		in, out := &in.IsSecretDataBase64, &out.IsSecretDataBase64
		*out = new(bool)
		**out = **in
	}
	if in.ResourceID != nil {
		in, out := &in.ResourceID, &out.ResourceID
		*out = new(string)
		**out = **in
	}
	if in.SecretData != nil {
		in, out := &in.SecretData, &out.SecretData
		*out = new(SecretversionSecretData)
		(*in).DeepCopyInto(*out)
	}
	if in.SecretRef != nil {
		in, out := &in.SecretRef, &out.SecretRef
		*out = new(v1alpha1.ResourceRef)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretVersionSpec.
func (in *SecretManagerSecretVersionSpec) DeepCopy() *SecretManagerSecretVersionSpec {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretVersionSpec)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretManagerSecretVersionStatus) DeepCopyInto(out *SecretManagerSecretVersionStatus) {
	*out = *in
	if in.Conditions != nil {
		in, out := &in.Conditions, &out.Conditions
		*out = make([]v1alpha1.Condition, len(*in))
		copy(*out, *in)
	}
	if in.CreateTime != nil {
		in, out := &in.CreateTime, &out.CreateTime
		*out = new(string)
		**out = **in
	}
	if in.DestroyTime != nil {
		in, out := &in.DestroyTime, &out.DestroyTime
		*out = new(string)
		**out = **in
	}
	if in.Name != nil {
		in, out := &in.Name, &out.Name
		*out = new(string)
		**out = **in
	}
	if in.ObservedGeneration != nil {
		in, out := &in.ObservedGeneration, &out.ObservedGeneration
		*out = new(int64)
		**out = **in
	}
	if in.Version != nil {
		in, out := &in.Version, &out.Version
		*out = new(string)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretManagerSecretVersionStatus.
func (in *SecretManagerSecretVersionStatus) DeepCopy() *SecretManagerSecretVersionStatus {
	if in == nil {
		return nil
	}
	out := new(SecretManagerSecretVersionStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretObservedStateStatus) DeepCopyInto(out *SecretObservedStateStatus) {
	*out = *in
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretObservedStateStatus.
func (in *SecretObservedStateStatus) DeepCopy() *SecretObservedStateStatus {
	if in == nil {
		return nil
	}
	out := new(SecretObservedStateStatus)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretReplicas) DeepCopyInto(out *SecretReplicas) {
	*out = *in
	if in.CustomerManagedEncryption != nil {
		in, out := &in.CustomerManagedEncryption, &out.CustomerManagedEncryption
		*out = new(SecretCustomerManagedEncryption)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretReplicas.
func (in *SecretReplicas) DeepCopy() *SecretReplicas {
	if in == nil {
		return nil
	}
	out := new(SecretReplicas)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretReplication) DeepCopyInto(out *SecretReplication) {
	*out = *in
	if in.Auto != nil {
		in, out := &in.Auto, &out.Auto
		*out = new(SecretAuto)
		(*in).DeepCopyInto(*out)
	}
	if in.Automatic != nil {
		in, out := &in.Automatic, &out.Automatic
		*out = new(bool)
		**out = **in
	}
	if in.UserManaged != nil {
		in, out := &in.UserManaged, &out.UserManaged
		*out = new(SecretUserManaged)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretReplication.
func (in *SecretReplication) DeepCopy() *SecretReplication {
	if in == nil {
		return nil
	}
	out := new(SecretReplication)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretRotation) DeepCopyInto(out *SecretRotation) {
	*out = *in
	if in.NextRotationTime != nil {
		in, out := &in.NextRotationTime, &out.NextRotationTime
		*out = new(string)
		**out = **in
	}
	if in.RotationPeriod != nil {
		in, out := &in.RotationPeriod, &out.RotationPeriod
		*out = new(string)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretRotation.
func (in *SecretRotation) DeepCopy() *SecretRotation {
	if in == nil {
		return nil
	}
	out := new(SecretRotation)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretTopics) DeepCopyInto(out *SecretTopics) {
	*out = *in
	out.TopicRef = in.TopicRef
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretTopics.
func (in *SecretTopics) DeepCopy() *SecretTopics {
	if in == nil {
		return nil
	}
	out := new(SecretTopics)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretUserManaged) DeepCopyInto(out *SecretUserManaged) {
	*out = *in
	if in.Replicas != nil {
		in, out := &in.Replicas, &out.Replicas
		*out = make([]SecretReplicas, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretUserManaged.
func (in *SecretUserManaged) DeepCopy() *SecretUserManaged {
	if in == nil {
		return nil
	}
	out := new(SecretUserManaged)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretversionSecretData) DeepCopyInto(out *SecretversionSecretData) {
	*out = *in
	if in.Value != nil {
		in, out := &in.Value, &out.Value
		*out = new(string)
		**out = **in
	}
	if in.ValueFrom != nil {
		in, out := &in.ValueFrom, &out.ValueFrom
		*out = new(SecretversionValueFrom)
		(*in).DeepCopyInto(*out)
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretversionSecretData.
func (in *SecretversionSecretData) DeepCopy() *SecretversionSecretData {
	if in == nil {
		return nil
	}
	out := new(SecretversionSecretData)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *SecretversionValueFrom) DeepCopyInto(out *SecretversionValueFrom) {
	*out = *in
	if in.SecretKeyRef != nil {
		in, out := &in.SecretKeyRef, &out.SecretKeyRef
		*out = new(v1alpha1.SecretKeyRef)
		**out = **in
	}
	return
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new SecretversionValueFrom.
func (in *SecretversionValueFrom) DeepCopy() *SecretversionValueFrom {
	if in == nil {
		return nil
	}
	out := new(SecretversionValueFrom)
	in.DeepCopyInto(out)
	return out
}
