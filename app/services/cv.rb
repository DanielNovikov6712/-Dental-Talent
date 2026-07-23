# CV ingestion namespace.
#
# The pipeline is intentionally split into three replaceable stages so the
# extraction strategy can evolve independently (e.g. swapping the heuristic
# parser for an LLM-backed one) without touching the rest of the flow:
#
#   1. Cv::TextExtractor  — attached file  -> plain text
#   2. Cv::HeuristicParser — plain text    -> Cv::ParsedResult (pure data)
#   3. Cv::ProfileMapper   — ParsedResult  -> persisted CandidateProfile prefill
#
# ParseCandidateCvJob wires the three together in the background.
module Cv
  # Raised when a file's type is not one we can extract text from.
  class UnsupportedFileError < StandardError; end
end
