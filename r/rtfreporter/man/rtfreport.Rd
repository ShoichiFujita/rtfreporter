\name{rtfreport}
\alias{rtfreport}
\title{RTF report object}
\description{
\code{rtfreport} is the R6 class generator for one RTF report. It stores the
document in a document -> section -> page hierarchy.
}
\usage{rtfreport$new(font_table = NULL, color_table = NULL, default_page = NULL, default_header = NULL, default_footer = NULL, default_format = NULL)}
\arguments{
\item{font_table}{Font table definition. The default is Courier only.}
\item{color_table}{Color table definition. The default is black only.}
\item{default_page}{Default page layout settings.}
\item{default_header}{Default header definition used when a section header is not set.}
\item{default_footer}{Default footer definition used when a section footer is not set.}
\item{default_format}{Default text and table formatting.}
}
\details{
The public methods include:
\itemize{
\item \code{add_section(header = NULL, footer = NULL)}
\item \code{add_page(section_index, title = NULL, content = list(), footer_notes = NULL, page_options = NULL)}
\item \code{add_table(section_index, page_index, data, footer = NULL, metadata = NULL)}
\item \code{add_listing(section_index, page_index, data, footer = NULL, metadata = NULL)}
\item \code{add_figure(section_index, page_index, path, footer = NULL, metadata = NULL)}
\item \code{add_section_from_dataframes(data_list, section_header = NULL, section_footer = NULL, page_titles = NULL, block_type = "table", page_footer_notes = NULL, metadata = NULL)}
\item \code{set_document_defaults(...)}
\item \code{set_default_header(header)}
\item \code{set_default_footer(footer)}
\item \code{set_default_page(page)}
\item \code{set_default_format(fmt)}
\item \code{validate()}
}

The convenience method \code{add_section_from_dataframes()} creates one new
section and appends one page per data frame in \code{data_list}.
}
\value{
An \code{R6ClassGenerator} object.
}
\examples{
report <- rtfreport$new()
sec <- report$add_section()
report$add_page(sec, title = "Example page")
}