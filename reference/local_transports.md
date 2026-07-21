# Local OpenLineage transports

Offline transports for testing, local development, and disabled
emission. Every `emit(event)` method accepts a `RunEvent` model and
returns that event invisibly after success.

## Value

An R6 transport object.

## Details

`AccumulatingTransport` stores emitted models in its public `events`
list. Its `clear()` method removes all accumulated events and returns
the transport invisibly.

`ConsoleTransport` writes one JSON event to `stream`. Set
`pretty = TRUE` for indented output.

`NoopTransport` validates an event but performs no output or storage.

All transports provide
[`close()`](https://rdrr.io/r/base/connections.html), which returns
`TRUE` invisibly because the local transports have no pending work.

## Super class

`OpenLineageTransport` -\> `AccumulatingTransport`

## Public fields

- `events`:

  Emitted `RunEvent` models in emission order.

## Methods

### Public methods

- [`AccumulatingTransport$new()`](#method-AccumulatingTransport-initialize)

- [`AccumulatingTransport$emit()`](#method-AccumulatingTransport-emit)

- [`AccumulatingTransport$clear()`](#method-AccumulatingTransport-clear)

- [`AccumulatingTransport$clone()`](#method-AccumulatingTransport-clone)

Inherited methods

- `OpenLineageTransport$close()`

------------------------------------------------------------------------

### `AccumulatingTransport$new()`

Create an empty accumulating transport.

#### Usage

    AccumulatingTransport$new()

#### Returns

A new `AccumulatingTransport` object.

------------------------------------------------------------------------

### `AccumulatingTransport$emit()`

Store an event.

#### Usage

    AccumulatingTransport$emit(event)

#### Arguments

- `event`:

  A `RunEvent` model.

#### Returns

`event`, invisibly.

------------------------------------------------------------------------

### `AccumulatingTransport$clear()`

Remove all stored events.

#### Usage

    AccumulatingTransport$clear()

#### Returns

The transport, invisibly.

------------------------------------------------------------------------

### `AccumulatingTransport$clone()`

The objects of this class are cloneable with this method.

#### Usage

    AccumulatingTransport$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`OpenLineageTransport` -\> `ConsoleTransport`

## Methods

### Public methods

- [`ConsoleTransport$new()`](#method-ConsoleTransport-initialize)

- [`ConsoleTransport$emit()`](#method-ConsoleTransport-emit)

- [`ConsoleTransport$clone()`](#method-ConsoleTransport-clone)

Inherited methods

- `OpenLineageTransport$close()`

------------------------------------------------------------------------

### `ConsoleTransport$new()`

Create a console transport.

#### Usage

    ConsoleTransport$new(stream = stdout(), pretty = TRUE)

#### Arguments

- `stream`:

  An open, writable R connection.

- `pretty`:

  Whether JSON should be indented.

#### Returns

A new `ConsoleTransport` object.

------------------------------------------------------------------------

### `ConsoleTransport$emit()`

Serialize and write an event to the configured connection.

#### Usage

    ConsoleTransport$emit(event)

#### Arguments

- `event`:

  A `RunEvent` model.

#### Returns

`event`, invisibly.

------------------------------------------------------------------------

### `ConsoleTransport$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ConsoleTransport$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Super class

`OpenLineageTransport` -\> `NoopTransport`

## Methods

### Public methods

- [`NoopTransport$emit()`](#method-NoopTransport-emit)

- [`NoopTransport$clone()`](#method-NoopTransport-clone)

Inherited methods

- `OpenLineageTransport$close()`

------------------------------------------------------------------------

### `NoopTransport$emit()`

Validate an event without emitting it.

#### Usage

    NoopTransport$emit(event)

#### Arguments

- `event`:

  A `RunEvent` model.

#### Returns

`event`, invisibly.

------------------------------------------------------------------------

### `NoopTransport$clone()`

The objects of this class are cloneable with this method.

#### Usage

    NoopTransport$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
transport <- AccumulatingTransport$new()
event <- RunEvent(
  Run(new_run_id()),
  Job("example", "task"),
  event_type = "START"
)
transport$emit(event)
length(transport$events)
#> [1] 1

console <- ConsoleTransport$new(pretty = FALSE)
noop <- NoopTransport$new()
noop$emit(event)
```
