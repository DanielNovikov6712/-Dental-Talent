module Cv
  class ParseText
    include Interactor

    def call
      context.parsed_result = Cv::HeuristicParser.call(context.text)
    end
  end
end
