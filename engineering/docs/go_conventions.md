
## General

### Logging

Use `github.com/solo-io/go-utils/contextutils` for logging. 
Initialize a context with useful information, including a version field.

```go
func getInitialContext() context.Context {
	loggingContext := []interface{}{"version", version.Version}
	ctx := contextutils.WithLogger(context.Background(), BotName)
	ctx = contextutils.WithLoggerValues(ctx, loggingContext...)
	return ctx
}
```

Log using zap fields where possible. If a number of fields are added, break the line into a single
 field per line: For instance:

```go
contextutils.LoggerFrom(ctx).Infow("Downloading repo archive",
			zap.String("owner", r.owner),
			zap.String("repo", r.repo),
			zap.String("sha", r.sha))
```

### Interfaces

Define interfaces when writing new utilities/modules that allow for mocking out dependencies and unit testing. 
The default struct implementation for an interface should have the same name, with a lowercase first letter. 
A constructor should be used for instantiation. The interface, struct, and constructor should be near the top of a file. 

```go
type ChangelogReader interface {
	GetChangelogForTag(ctx context.Context, tag string) (*Changelog, error)
	ReadChangelogFile(ctx context.Context, path string) (*ChangelogFile, error)
}

type changelogReader struct {
	code vfsutils.MountedRepo
}

func NewChangelogReader(code vfsutils.MountedRepo) ChangelogReader {
	return &changelogReader{code: code}
}

func (c* changelogReader) GetChangelogForTag(ctx context.Context, tag string) (*Changelog, error) {
	...
}

func (c* changelogReader) ReadChangelogFile(ctx context.Context, path string) (*ChangelogFile, error) {
	...
}
```

### Testing

Unit tests should be written for every new interface function implementation or public function. 
Mockgen should be used as necessary to mock out underlying implementation dependencies. 
Unit tests should be written for every error and interesting edge case. 

### Tracking changes

Repos should prefer to use changelogs and solobot for issue/PR linking and release management. 
See https://github.com/solo-io/go-utils/tree/master/changelogutils.

## Errors

### Defining errors 

Errors should be defined near the top of a go file in a var section. If an error requires parameters or wraps another
error, then a function that produces an error should be defined; otherwise the error should be constructed. The name
of the variable should explain the error and end in the word `Error`. 
[Here](https://github.com/solo-io/go-utils/blob/60436767a0379abc08c12814fdfb8bb84f301a3a/changelogutils/reader.go) 
is an example go snippet:

```go
var (
	UnableToListFilesError = func(err error, directory string) error {
		return errors.Wrapf(err, "Unable to list files in directory %s", directory)
	}
	UnexpectedDirectoryError = func(name, directory string) error {
		return errors.Errorf("Unexpected directory %s in changelog directory %s", name, directory)
	}
	UnableToReadSummaryFileError = func(err error, path string) error {
		return errors.Wrapf(err, "Unable to read summary file %s", path)
	}
	UnableToReadClosingFileError = func(err error, path string) error {
		return errors.Wrapf(err, "Unable to read closing file %s", path)
	}
	NoEntriesInChangelogError = func(filename string) error {
		return errors.Errorf("No changelog entries found in file %s.", filename)
	}
	UnableToParseChangelogError = func(err error, path string) error {
		return errors.Wrapf(err, "File %s is not a valid changelog file.", path)
	}
	MissingIssueLinkError = errors.Errorf("Changelog entries must have an issue link")
	MissingDescriptionError = errors.Errorf("Changelog entries must have a description")
	MissingOwnerError = errors.Errorf("Dependency bumps must have an owner")
	MissingRepoError = errors.Errorf("Dependency bumps must have a repo")
	MissingTagError = errors.Errorf("Dependency bumps must have a tag")
)
```

### Testing for errors

A test should be written to check for any possible typed error that a function may return. 

For errors that are singletons, the error can be tested using a gomega equality check: 
```go
Expect(err).To(Equal(MissingTagError))
```

If an error is produced by a function, but does not wrap another error, the exact error message can be compared:
```go
Expect(err.Error()).To(Equal(NoEntriesInChangelogError("foo").Error()))
```

If an error wraps another, then a substring match can be used instead:

If an error is produced by a function, and wraps another error that can not be simulated in the test, then a substring
match can be used instead:
```go
Expect(err.Error()).To(ContainSubstring(UnableToReadSummaryFileError(errors.Errorf(""), path).Error()))
```

### Logging errors

Include the error as a zap field. If the error is wrapped, log the wrapped message and the nested error:

```go
if err != nil {
  wrapped := FailedToListArtifactsError(err, ns)
  contextutils.LoggerFrom(s.ctx).Errorw(wrapped.Error(), zap.Error(err), zap.Any("request", request))
  return wrapped
}
```

