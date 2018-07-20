# NOTE: This does not check the metadata.
RSpec::Matchers.define :match_events do |expected_events|
  match do |actual_events|
    expected_events.zip(actual_events).each do |expected_event, actual_event|
      expect(expected_event.class).to eq actual_event.class
      expect(expected_event.aggregate_id).to eq actual_event.aggregate_id
      expect(expected_event.aggregate_sequence_id).to eq actual_event.aggregate_sequence_id
      expect(EventFramework::EventStore::Sink::EventBodySerializer.call(expected_event.to_h))
        .to eq EventFramework::EventStore::Sink::EventBodySerializer.call(actual_event.to_h)
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
