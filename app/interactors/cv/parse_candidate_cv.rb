module Cv
  class ParseCandidateCv
    include Interactor::Organizer

    before do
      context.document.mark_processing!
      context.profile = context.document.candidate_profile
    end

    organize ExtractText, ParseText, MapProfile

    after do
      context.document.mark_completed!(context.parsed_result.to_h)
    end
  end
end
