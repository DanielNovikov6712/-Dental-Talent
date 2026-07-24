require "pdf-reader"
require "docx"

module Cv
  class ExtractText
    include Interactor

    SUPPORTED_EXTENSIONS = %w[.pdf .docx .doc].freeze

    DOC_SCAN_BYTES = 2.megabytes

    def call
      document = context.document
      context.fail!(error: I18n.t("onboarding.parsing.unreadable")) unless document.file.attached?

      extension = File.extname(document.original_filename.to_s).downcase
      context.fail!(error: I18n.t("onboarding.parsing.unsupported")) unless SUPPORTED_EXTENSIONS.include?(extension)

      text = safe_extract(document, extension)
      context.fail!(error: I18n.t("onboarding.parsing.unreadable")) if text.blank?

      context.text = text
    end

    private

    def safe_extract(document, extension)
      document.file.blob.open do |tempfile|
        case extension
        when ".pdf"  then extract_pdf(tempfile.path)
        when ".docx" then extract_docx(tempfile.path)
        when ".doc"  then extract_doc(tempfile.path)
        end
      end
    rescue => error
      Rails.logger.warn("CV text extraction failed for document #{context.document.id}: #{error.class}: #{error.message}")
      ""
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

    def extract_doc(path)
      raw = normalize(File.binread(path, DOC_SCAN_BYTES))
      runs = raw.scan(/[[:print:]\t]{4,}/).map(&:strip).reject(&:blank?)
      text = runs.join("\n")
      text.length >= 40 ? text : ""
    end

    def normalize(text)
      text.to_s.dup.force_encoding("UTF-8").scrub(" ")
    end
  end
end
