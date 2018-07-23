# NOTE: This does not check the metadata content.
RSpec::Matchers.define :match_events do |expected_events|
  match do |actual_events|
    @errors = Hash.new { |h, k| h[k] = [] }

    actual_events.zip(expected_events).each_with_index do |(actual_event, expected_event), i|
      @errors[i] << :event_class unless actual_event.class == expected_event.class
      @errors[i] << :aggregate_id unless actual_event.aggregate_id == expected_event.aggregate_id
      @errors[i] << :aggregate_sequence unless actual_event.aggregate_sequence == expected_event.aggregate_sequence

      # body
      actual_event_body = EventFramework::EventStore::Sink::EventBodySerializer.call(actual_event.to_h)
      expected_event_body = EventFramework::EventStore::Sink::EventBodySerializer.call(expected_event.to_h)
      @errors[i] << :body unless actual_event_body == expected_event_body

      # metadata
      @errors[i] << :metadata_class unless actual_event.metadata.class == EventFramework::Event::Metadata
      @errors[i] << :metadata_created_at unless actual_event.metadata.created_at.class == expected_event.metadata.created_at.class
    end

    @errors.empty?
  end

  failure_message do |actual_events|
    message = ""

    @errors.each do |i, errors|
      message << <<~MATCH_FAIL_MSG
        Event at index #{i} did not match, error(s): #{errors.join(', ')}
          expected:
            #{expected_events[i].inspect}
          got:
            #{actual_events[i].inspect}

      MATCH_FAIL_MSG
    end

    message
  end
end
