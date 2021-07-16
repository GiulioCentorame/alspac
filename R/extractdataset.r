#' Extract a dataset for external ALSPAC users
#'
#' @param variable_file CSV file with column "Name" containing
#' ALSPAC variable names.
#' @param cid_file CSV file with two columns named "ALN" and the last letter
#' of the filename (e.g. for "ACEHDBFG.txt" the column would be named "G").
#' @param b_number B number of the project.
#' @param author Last name of the project author.
#' @param output_format "sav","csv" or "dta" (Default: "sav").
#' @param output_path File path of output file, default is the current directory (Default: ".").
#' @param output_file Dataset file (should not already exist). Default is
#' derived from function arguments as follows:
#' <output_path>/<author>_<b_number>_<date>.<output_format>.
#' @param dictionary ALSPAC dictionary to use "current", "useful" or "both"
#' (Default: "both").
#' @return Saves the output dataset to `output_file` and returns it. 
#'
#' @examples\dontrun{
#' library(alspac)
#' setDataDir("R:/Data")
#' dat <- extractDataset(
#'          variable_file="ACEHDBFG.txt",
#'          cid_file="Vars_from_Explore.csv",
#'          output_format="sav",
#'          b_number="B0001",
#'          author="Smith")
#' ## creates a data file with a name like "Smith_B0001_12Jul21.sav"
#' ## in the current directory
#' }
#' @export
extractDataset <- function(variable_file, cid_file,
                           b_number="BXXXX", author="Author",
                           output_format="sav",
                           output_path=".",
                           output_file=file.path(
                               output_path,
                               paste0(
                                   author, "_",
                                   b_number, "_",
                                   format(Sys.time(), "%d%b%y"),
                                   ".", output_format)),
                           dictionary="both") {
    stopifnot(output_format %in% c("sav","csv","dta"))
    if (file.exists(output_file))
        stop("Output file already exists: ", output_file)
        
    cid_map <- read.csv(cid_file,stringsAsFactors=F)
    cid_column <- tolower(sub(".*(.{1})\\.[^.]*","\\1",cid_file))
    colnames(cid_map) <- tolower(colnames(cid_map))
    if (!"aln" %in% colnames(cid_map))
        stop("ALN column is missing from ", cid_file)
    if (!cid_column %in% colnames(cid_map))
        stop("CID column ", cid_column, " is missing from ", cid_file)

    variables <- read.csv(variable_file,stringsAsFactors=F)
    colnames(variables) <- tolower(colnames(variables))
    if (!"name" %in% colnames(variables))
        stop("Variable name column 'name' is missing from ", variables_file)
    
    dictionary <- alspac:::retrieveDictionary(dictionary)
    idx <- match(tolower(variables$name), tolower(dictionary$name))
    
    if (any(is.na(idx))) {
        if (all(is.na(idx)))
            stop("None of the requested variables could be found.")
        else {
            msg <- paste("Several requested variables could not be found:",
                         paste(variables$name[is.na(idx)],collapse=", "))            
            warning(msg)
        }
        idx <- na.omit(idx)
    }
    dictionary <- dictionary[idx,]
    
    dat <- extractVars(dictionary, haven=TRUE)

    idx <- match(
        as.character(dat$aln),
        as.character(cid_map$aln))

    dat$aln <- cid_map$g[idx]
    colnames(dat)[colnames(dat)=="aln"] <- paste0("cid",b_number)
    
    if ("alnqlet" %in% colnames(dat))
        dat[["alnqlet"]] <- NULL

    message("Saving output to ", output_file, "\n")
    if (output_format=="dta")
        haven::write_dta(dat, path=output_file)
    else if (output_format=="csv")
        write.csv(dat, file=output_file, row.names=F)
    else if (output_format=="sav")
        haven::write_sav(dat, path=output_file, compress=T)
    
    invisible(dat)
}
