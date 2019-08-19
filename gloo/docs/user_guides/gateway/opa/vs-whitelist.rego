package kubernetes.admission

operations = {"CREATE", "UPDATE"}

deny[msg] {
	input.request.kind.kind == "VirtualService"
	operations[input.request.operation]
	input.request.object.spec.routes[_].routePlugins.prefixRewrite
	msg := "no prefix re-write"
}
