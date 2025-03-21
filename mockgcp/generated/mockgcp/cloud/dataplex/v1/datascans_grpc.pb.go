// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.2.0
// - protoc             v3.12.4
// source: mockgcp/cloud/dataplex/v1/datascans.proto

package dataplexpb

import (
	longrunningpb "cloud.google.com/go/longrunning/autogen/longrunningpb"
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

// DataScanServiceClient is the client API for DataScanService service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type DataScanServiceClient interface {
	// Creates a DataScan resource.
	CreateDataScan(ctx context.Context, in *CreateDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error)
	// Updates a DataScan resource.
	UpdateDataScan(ctx context.Context, in *UpdateDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error)
	// Deletes a DataScan resource.
	DeleteDataScan(ctx context.Context, in *DeleteDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error)
	// Gets a DataScan resource.
	GetDataScan(ctx context.Context, in *GetDataScanRequest, opts ...grpc.CallOption) (*DataScan, error)
	// Lists DataScans.
	ListDataScans(ctx context.Context, in *ListDataScansRequest, opts ...grpc.CallOption) (*ListDataScansResponse, error)
	// Runs an on-demand execution of a DataScan
	RunDataScan(ctx context.Context, in *RunDataScanRequest, opts ...grpc.CallOption) (*RunDataScanResponse, error)
	// Gets a DataScanJob resource.
	GetDataScanJob(ctx context.Context, in *GetDataScanJobRequest, opts ...grpc.CallOption) (*DataScanJob, error)
	// Lists DataScanJobs under the given DataScan.
	ListDataScanJobs(ctx context.Context, in *ListDataScanJobsRequest, opts ...grpc.CallOption) (*ListDataScanJobsResponse, error)
	// Generates recommended data quality rules based on the results of a data
	// profiling scan.
	//
	// Use the recommendations to build rules for a data quality scan.
	GenerateDataQualityRules(ctx context.Context, in *GenerateDataQualityRulesRequest, opts ...grpc.CallOption) (*GenerateDataQualityRulesResponse, error)
}

type dataScanServiceClient struct {
	cc grpc.ClientConnInterface
}

func NewDataScanServiceClient(cc grpc.ClientConnInterface) DataScanServiceClient {
	return &dataScanServiceClient{cc}
}

func (c *dataScanServiceClient) CreateDataScan(ctx context.Context, in *CreateDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error) {
	out := new(longrunningpb.Operation)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/CreateDataScan", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) UpdateDataScan(ctx context.Context, in *UpdateDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error) {
	out := new(longrunningpb.Operation)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/UpdateDataScan", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) DeleteDataScan(ctx context.Context, in *DeleteDataScanRequest, opts ...grpc.CallOption) (*longrunningpb.Operation, error) {
	out := new(longrunningpb.Operation)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/DeleteDataScan", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) GetDataScan(ctx context.Context, in *GetDataScanRequest, opts ...grpc.CallOption) (*DataScan, error) {
	out := new(DataScan)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/GetDataScan", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) ListDataScans(ctx context.Context, in *ListDataScansRequest, opts ...grpc.CallOption) (*ListDataScansResponse, error) {
	out := new(ListDataScansResponse)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/ListDataScans", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) RunDataScan(ctx context.Context, in *RunDataScanRequest, opts ...grpc.CallOption) (*RunDataScanResponse, error) {
	out := new(RunDataScanResponse)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/RunDataScan", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) GetDataScanJob(ctx context.Context, in *GetDataScanJobRequest, opts ...grpc.CallOption) (*DataScanJob, error) {
	out := new(DataScanJob)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/GetDataScanJob", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) ListDataScanJobs(ctx context.Context, in *ListDataScanJobsRequest, opts ...grpc.CallOption) (*ListDataScanJobsResponse, error) {
	out := new(ListDataScanJobsResponse)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/ListDataScanJobs", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *dataScanServiceClient) GenerateDataQualityRules(ctx context.Context, in *GenerateDataQualityRulesRequest, opts ...grpc.CallOption) (*GenerateDataQualityRulesResponse, error) {
	out := new(GenerateDataQualityRulesResponse)
	err := c.cc.Invoke(ctx, "/mockgcp.cloud.dataplex.v1.DataScanService/GenerateDataQualityRules", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DataScanServiceServer is the server API for DataScanService service.
// All implementations must embed UnimplementedDataScanServiceServer
// for forward compatibility
type DataScanServiceServer interface {
	// Creates a DataScan resource.
	CreateDataScan(context.Context, *CreateDataScanRequest) (*longrunningpb.Operation, error)
	// Updates a DataScan resource.
	UpdateDataScan(context.Context, *UpdateDataScanRequest) (*longrunningpb.Operation, error)
	// Deletes a DataScan resource.
	DeleteDataScan(context.Context, *DeleteDataScanRequest) (*longrunningpb.Operation, error)
	// Gets a DataScan resource.
	GetDataScan(context.Context, *GetDataScanRequest) (*DataScan, error)
	// Lists DataScans.
	ListDataScans(context.Context, *ListDataScansRequest) (*ListDataScansResponse, error)
	// Runs an on-demand execution of a DataScan
	RunDataScan(context.Context, *RunDataScanRequest) (*RunDataScanResponse, error)
	// Gets a DataScanJob resource.
	GetDataScanJob(context.Context, *GetDataScanJobRequest) (*DataScanJob, error)
	// Lists DataScanJobs under the given DataScan.
	ListDataScanJobs(context.Context, *ListDataScanJobsRequest) (*ListDataScanJobsResponse, error)
	// Generates recommended data quality rules based on the results of a data
	// profiling scan.
	//
	// Use the recommendations to build rules for a data quality scan.
	GenerateDataQualityRules(context.Context, *GenerateDataQualityRulesRequest) (*GenerateDataQualityRulesResponse, error)
	mustEmbedUnimplementedDataScanServiceServer()
}

// UnimplementedDataScanServiceServer must be embedded to have forward compatible implementations.
type UnimplementedDataScanServiceServer struct {
}

func (UnimplementedDataScanServiceServer) CreateDataScan(context.Context, *CreateDataScanRequest) (*longrunningpb.Operation, error) {
	return nil, status.Errorf(codes.Unimplemented, "method CreateDataScan not implemented")
}
func (UnimplementedDataScanServiceServer) UpdateDataScan(context.Context, *UpdateDataScanRequest) (*longrunningpb.Operation, error) {
	return nil, status.Errorf(codes.Unimplemented, "method UpdateDataScan not implemented")
}
func (UnimplementedDataScanServiceServer) DeleteDataScan(context.Context, *DeleteDataScanRequest) (*longrunningpb.Operation, error) {
	return nil, status.Errorf(codes.Unimplemented, "method DeleteDataScan not implemented")
}
func (UnimplementedDataScanServiceServer) GetDataScan(context.Context, *GetDataScanRequest) (*DataScan, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetDataScan not implemented")
}
func (UnimplementedDataScanServiceServer) ListDataScans(context.Context, *ListDataScansRequest) (*ListDataScansResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method ListDataScans not implemented")
}
func (UnimplementedDataScanServiceServer) RunDataScan(context.Context, *RunDataScanRequest) (*RunDataScanResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method RunDataScan not implemented")
}
func (UnimplementedDataScanServiceServer) GetDataScanJob(context.Context, *GetDataScanJobRequest) (*DataScanJob, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetDataScanJob not implemented")
}
func (UnimplementedDataScanServiceServer) ListDataScanJobs(context.Context, *ListDataScanJobsRequest) (*ListDataScanJobsResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method ListDataScanJobs not implemented")
}
func (UnimplementedDataScanServiceServer) GenerateDataQualityRules(context.Context, *GenerateDataQualityRulesRequest) (*GenerateDataQualityRulesResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GenerateDataQualityRules not implemented")
}
func (UnimplementedDataScanServiceServer) mustEmbedUnimplementedDataScanServiceServer() {}

// UnsafeDataScanServiceServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to DataScanServiceServer will
// result in compilation errors.
type UnsafeDataScanServiceServer interface {
	mustEmbedUnimplementedDataScanServiceServer()
}

func RegisterDataScanServiceServer(s grpc.ServiceRegistrar, srv DataScanServiceServer) {
	s.RegisterService(&DataScanService_ServiceDesc, srv)
}

func _DataScanService_CreateDataScan_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(CreateDataScanRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).CreateDataScan(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/CreateDataScan",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).CreateDataScan(ctx, req.(*CreateDataScanRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_UpdateDataScan_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(UpdateDataScanRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).UpdateDataScan(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/UpdateDataScan",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).UpdateDataScan(ctx, req.(*UpdateDataScanRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_DeleteDataScan_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(DeleteDataScanRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).DeleteDataScan(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/DeleteDataScan",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).DeleteDataScan(ctx, req.(*DeleteDataScanRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_GetDataScan_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(GetDataScanRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).GetDataScan(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/GetDataScan",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).GetDataScan(ctx, req.(*GetDataScanRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_ListDataScans_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ListDataScansRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).ListDataScans(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/ListDataScans",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).ListDataScans(ctx, req.(*ListDataScansRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_RunDataScan_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(RunDataScanRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).RunDataScan(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/RunDataScan",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).RunDataScan(ctx, req.(*RunDataScanRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_GetDataScanJob_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(GetDataScanJobRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).GetDataScanJob(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/GetDataScanJob",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).GetDataScanJob(ctx, req.(*GetDataScanJobRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_ListDataScanJobs_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ListDataScanJobsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).ListDataScanJobs(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/ListDataScanJobs",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).ListDataScanJobs(ctx, req.(*ListDataScanJobsRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _DataScanService_GenerateDataQualityRules_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(GenerateDataQualityRulesRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(DataScanServiceServer).GenerateDataQualityRules(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/mockgcp.cloud.dataplex.v1.DataScanService/GenerateDataQualityRules",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(DataScanServiceServer).GenerateDataQualityRules(ctx, req.(*GenerateDataQualityRulesRequest))
	}
	return interceptor(ctx, in, info, handler)
}

// DataScanService_ServiceDesc is the grpc.ServiceDesc for DataScanService service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var DataScanService_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "mockgcp.cloud.dataplex.v1.DataScanService",
	HandlerType: (*DataScanServiceServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "CreateDataScan",
			Handler:    _DataScanService_CreateDataScan_Handler,
		},
		{
			MethodName: "UpdateDataScan",
			Handler:    _DataScanService_UpdateDataScan_Handler,
		},
		{
			MethodName: "DeleteDataScan",
			Handler:    _DataScanService_DeleteDataScan_Handler,
		},
		{
			MethodName: "GetDataScan",
			Handler:    _DataScanService_GetDataScan_Handler,
		},
		{
			MethodName: "ListDataScans",
			Handler:    _DataScanService_ListDataScans_Handler,
		},
		{
			MethodName: "RunDataScan",
			Handler:    _DataScanService_RunDataScan_Handler,
		},
		{
			MethodName: "GetDataScanJob",
			Handler:    _DataScanService_GetDataScanJob_Handler,
		},
		{
			MethodName: "ListDataScanJobs",
			Handler:    _DataScanService_ListDataScanJobs_Handler,
		},
		{
			MethodName: "GenerateDataQualityRules",
			Handler:    _DataScanService_GenerateDataQualityRules_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "mockgcp/cloud/dataplex/v1/datascans.proto",
}
