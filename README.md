# EventFramework

EventFramework is the event-sourcing framework developed by the Murmur team. The
API has been designed to make the happy-path simple, and the complex-path
uncomplicated.

## Domain Objects

In order to reduce the risk of naming collisions with existing murmur code, domain
objects should be implemented in a module, under `Domains`, named after the
primary Aggregate:

```ruby
module Domains
  module Person
    class EmailAddressChanged < EventFramework::DomainEvent
    end

    class ChangeEmailAddressCommand < EventFramework::Command
    end

    class ChangeEmailAddressCommandHandler < EventFramework::CommandHandler
    end

    class PersonAggregate < EventFramework::Aggregate
    end
  end
end
```

As you can see from the example above, `EventFramework` provides several base
classes that can be used to build domain objects.

### Command

`Command` is a means of describing and encapsulating the data required when
executing a command against an aggregate.

```ruby
class ChangeEmailAddressCommand < EventFramework::Command
  attribute :person_id, Types::UUID
  attribute :email_address, Types::Strict::String
end
```

`Command` is implemented as a [dry-struct](http://dry-rb.org/gems/dry-struct/),
allowing us to build concise, self-documenting, mostly-type-safe data objects.

### CommandHandler

In general terms, a `CommandHandler` acts as the bridge between an external source
of input and  and the intended aggregate. In our current use-case, this means
Rails controller actions.

The `CommandHandler` negotiates the process of instantiating an aggregate and
re-building its internal state from the events in the event store:

```ruby
class ChangeEmailAddressCommandHandler < EventFramework::CommandHandler
  def handle(command)
    metadata.causation_id = "d1bee3f5-0ce6-4483-bd54-8f007260ee19"

    with_aggregate(Person, command.person_id) do |survey|
      person.change_email_address(command: command, metadata: metadata)
    end
  end
end
```

Instances of `CommandHandler` also provide a `metadata` object, which can be
used to capture request-level data for persistence into the event store.

EventFramework includes a module (TODO: add link once merged) that can be
included in a Rails controller and will help instantiate a `CommandHandler` that
is pre-seeded with all the required metadata.

### Aggregate

All aggregates inherit from the `Aggregate` base class. Building internal state
is handled by a collection of event handlers, defined on the class using the
`apply` helper method:

```ruby
class PersonAggregate < EventFramework::Aggregate
  apply :EmailAddressChanged do |event|
    @email_address = event.email_address
  end
end
```

Commands are implemented as standard methods on the aggregate class. Persisting
the event to the event store is handled by calling `sink_event`.

```ruby
class PersonAggregate < EventFramework::Aggregate
  def change_email_address(command:, metadata:)
    raise EmailNotChanged if command.email_address == @email_address

    sink_event Events::EmailAddressChanged.new(email_address: command.email_address), metadata
  end
end
```

If you are implementing a command that will generate multiple events witin that
command, each event can be staged by calling `stage_event`, and then persisted
by calling `sink_staged_events`

```ruby
class PersonAggregate < EventFramework::Aggregate
  def modify_attributes(command:, metadata:)
    stage_event Events::AlignmentChanged(alignment: command.alignment) if @alignment != command.alignment
    stage_event Events::OriginStoryChanged(origin_story: command.origin_story) if @origin_story != command.origin_story

    sink_staged_events
  end
end
```

## Domain Events

In the example above, you would have noticed a class called
`Events::EmailAddressChanged` being instantiated within the command.

EventFramework refers to these classes as Domain Events.

Every Domain Event that can be generated by our platform is described by a single
Ruby class (inheriting from `DomainEvent`) that belongs to the `Events` module:

```ruby
module Events
  class EmailAddressChangedForPerson < EventFramework::DomainEvent
    attribute :new_email_address, Types::Strict::String
  end
end
```

As with `Command`, `DomainEvent` uses `dry-struct` under the hood.

### Internal Persistence

When domain events (and associated metadata) are sunk into the event store, they
are persisted into a PostgreSQL database.

When sourced from the event store, they are encapsulated in a generic `Event`
object. `Event` also contains metadata and additional details from the database:

Attribute            | Description
---------------------|----------------------------------------------------------
`id`                 | The primary key of the event; UUIDv4, automatically generated by the database
`sequence`           | The position of this event in the entire event stream; Automatically generated by the database
`aggregate_id`       | The ID of the aggregate that this event pertains to
`aggregate_sequence` | The position of this event within the aggregate-specific event stream. Integer, generated within the aggregate.
`domain_event`       | An instance of the `DomainEvent` class, populated with the contents of the event body.
`metadata`           | A Struct that contains the following pieces of metadata:

#### Event Metadata

Attribute            | Description
---------------------|----------------------------------------------------------
`user_id`            | The ID of the User who performed the action. Currently taken from Mumur's _authn_ system.
`correlation_id`     | The correlation ID of the event; Usually generated as a unique request ID in the client, and passed via the HTTP request
`causation_id`       | The ID of the Event that caused _this_ Event to be created via a Reactor.
`created_at`         | The time and date (in UTC) that event saved to the database; Automatically generated by the database.



