require "pdf-reader"
require "docx"

module Cv
  # Extracts plain text from an uploaded CV (PDF / DOCX / best-effort DOC).
  # Never raises on malformed content — returns "" so the caller can fall back
  # to manual onboarding.
  class TextExtractor
    def self.call(document)
      new(document).extract
    end

    def initialize(document)
      @document = document
    end

    def extract
      return "" unless @document.file.attached?

      @document.file.blob.open do |tempfile|
        case extension
        when ".pdf"  then extract_pdf(tempfile.path)
        when ".docx" then extract_docx(tempfile.path)
        when ".doc"  then extract_doc(tempfile.path)
        else
          raise UnsupportedFileError, "Unsupported file type"
        end
      end
    rescue UnsupportedFileError
      raise
    rescue => error
      Rails.logger.warn("CV text extraction failed for document #{@document.id}: #{error.class}: #{error.message}")
      ""
    end

    private

    def extension
      File.extname(@document.original_filename.to_s).downcase
    end

    def extract_pdf(path)
      reader = PDF::Reader.new(path)
      normalize(reader.pages.map(&:text).join("\n"))
    end

    def extract_docx(path)
      doc = Docx::Document.open(path)
      paragraphs = doc.paragraphs.map(&:to_s)
      tables = doc.tables.flat_map { |table| table.rows.flat_map { |row| row.cells.map(&:text) } }
      normalize((paragraphs + tables).join("\n"))
    end

    # Legacy binary .doc has no reliable pure-Ruby parser. We scrape readable
    # runs so an email/phone can still be recovered; if too little survives we
    # return "" and the candidate continues manually.
    def extract_doc(path)
      raw = normalize(File.binread(path))
      runs = raw.scan(/[[:print:]\t]{4,}/).map(&:strip).reject(&:blank?)
      text = runs.join("\n")
      text.length >= 40 ? text : ""
    end

    # Force valid UTF-8 so downstream regex matching never raises on stray bytes
    # (e.g. PDFs with broken surrogate CMaps).
    def normalize(text)
      text.to_s.dup.force_encoding("UTF-8").scrub(" ")
    end
  end
end
