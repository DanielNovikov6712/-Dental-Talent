module Cv
  # Entry point for turning CV text into a Cv::ParsedResult. Delegates to the
  # configured strategy so the extraction approach can change in one place.
  #
  # A replacement strategy only needs a `.call(text) -> Cv::ParsedResult` method
  # (for example an LLM-backed parser that returns the same structured result).
  class Parser
    def self.call(text)
      strategy.call(text)
    end

    def self.strategy
      HeuristicParser
    end
  end
end
