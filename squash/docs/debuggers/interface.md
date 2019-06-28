---
title: Other
weight: 7
---

- It is easy to add support for additional languages and debuggers.
- Squash features an extendable debugger interface. Just implement the required methods for your preferred debugger.
- We have several additional debuggers on our roadmap and we welcome community contributions.

<aside class="notice" style="background: tan">
Interface documentation will be updated to reflect latest version.
<br>
Legacy Squash notes are shown below.
</aside>

**Debuggers** conform to the interface:

```go
type Debugger interface {

	/// Attach a debugger to pid and return the a debug server object
	Attach(pid int) (DebugServer, error)
}
```

Where `DebugServer` consists of the following:

```go
type DebugServer interface {
	/// Detach from the process we are debugging (allowing it to resume normal execution).
	Detach() error
	///  Return the port that the debug server listens on.
	Port() int
}
```

To add debugger support to squash, implement the functions above and add it to the squash client.

```go
func getDebugger(dbgtype string) debuggers.Debugger {

	var g gdb.GdbInterface
	var d dlv.DLV

	switch dbgtype {
	case "dlv":
		return &d
	case "gdb":
		return &g
	default:
		return nil
	}
}
```
