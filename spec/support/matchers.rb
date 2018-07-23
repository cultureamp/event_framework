# NOTE: This does not check the metadata content.
RSpec::Matchers.define :match_events do |expected_events|
  match do |actual_events|
    actual_events.zip(expected_events).each do |actual_event, expected_event|
      expect(actual_event.class).to eq expected_event.class
      expect(actual_event.aggregate_id).to eq expected_event.aggregate_id
      expect(actual_event.aggregate_sequence).to eq expected_event.aggregate_sequence

      # body
      expect(EventFramework::EventStore::Sink::EventBodySerializer.call(actual_event.to_h))
        .to eq EventFramework::EventStore::Sink::EventBodySerializer.call(expected_event.to_h)

      # metadata
      expect(actual_event.metadata).to be_a EventFramework::Event::Metadata
      expect(actual_event.metadata).to be_a expected_event.metadata.class
      expect(actual_event.metadata.created_at).to be_a Time
    end
  end

  failure_message do |actual_events|
    <<~MATCH_FAIL_MSG
      expected:

      #{actual_events.pretty_inspect}
      to eq:

      #{expected_events.pretty_inspect}
    MATCH_FAIL_MSG
  end
end
