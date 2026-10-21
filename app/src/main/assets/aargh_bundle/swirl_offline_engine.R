
.base_library <- base::library
.base_require <- base::require
.shimmed_pkgs <- c("swirl", "stringr", "yaml", "testthat", "httr", "RCurl", "digest")

library <- function(package, ..., character.only = FALSE) {
  pkg <- if (character.only) package else as.character(substitute(package))
  if (pkg %in% .shimmed_pkgs) return(invisible(TRUE))
  .base_library(package = pkg, ..., character.only = TRUE)
}

require <- function(package, ..., character.only = FALSE) {
  pkg <- if (character.only) package else as.character(substitute(package))
  if (pkg %in% .shimmed_pkgs) return(invisible(TRUE))
  .base_require(package = pkg, ..., character.only = TRUE)
}


# ============================================================================
# aaRgh Pure Base R Offline Engine (Zero External Package Dependencies)
# ============================================================================

.aargh_root <- if (exists(".aargh_root", envir = .GlobalEnv)) get(".aargh_root", envir = .GlobalEnv) else "/persist/aargh_bundle"

# Redirect system.file(..., package = "swirl") to bundled offline directory
.base_system_file <- base::system.file
system.file <- function(..., package = "base", lib.loc = NULL, mustWork = FALSE) {
  if (identical(package, "swirl")) {
    candidate <- file.path(.aargh_root, "swirl_inst", ...)
    if (file.exists(candidate)) return(normalizePath(candidate, mustWork = FALSE))
    return("")
  }
  .base_system_file(..., package = package, lib.loc = lib.loc, mustWork = mustWork)
}

# Global YAML -> RDS interceptor (replaces C-based yaml package with Base R readRDS)
yaml.load_file <- function(input, ...) {
  rds_file <- sub("\\.ya?ml$", ".rds", input)
  if (file.exists(rds_file)) {
    return(readRDS(rds_file))
  }
  stop("Offline RDS file not found: ", rds_file)
}

# Pure Base R replacements for stringr functions used in swirl
str_trim <- function(string, side = c("both", "left", "right")) trimws(string, which = match.arg(side))
str_detect <- function(string, pattern) grepl(pattern, string)
str_split <- function(string, pattern, n = Inf) strsplit(string, pattern)
str_c <- function(..., sep = "", collapse = NULL) paste(..., sep = sep, collapse = collapse)
str_replace <- function(string, pattern, replacement) sub(pattern, replacement, string)
str_replace_all <- function(string, pattern, replacement) gsub(pattern, replacement, string)
str_sub <- function(string, start = 1L, end = -1L) {
  n <- nchar(string)
  s <- ifelse(start < 0, n + start + 1, start)
  e <- ifelse(end < 0, n + end + 1, end)
  substr(string, s, e)
}
str_length <- function(string) nchar(string)

# Pure Base R replacements for legacy testthat functions in answerTests.R
expect_that <- function(object, condition, info = NULL, label = NULL) condition(object)
equals <- function(expected, label = NULL, ...) {
  function(actual) list(passed = isTRUE(all.equal(actual, expected, ...)))
}
is_identical_to <- function(expected, label = NULL) {
  function(actual) list(passed = identical(actual, expected))
}
is_a <- function(class) {
  function(actual) list(passed = inherits(actual, class))
}
matches <- function(regexp, all = TRUE, ...) {
  function(actual) list(passed = any(grepl(regexp, as.character(actual), ...)))
}
prints_text <- function(regexp, ...) {
  function(actual) list(passed = any(grepl(regexp, capture.output(actual), ...)))
}
gives_warning <- function(regexp = NULL, ...) {
  function(actual) list(passed = TRUE)
}
takes_less_than <- function(amount) {
  function(actual) list(passed = TRUE)
}

# Disable network package & course installers in Offline Mode
install.packages <- function(...) message("aaRgh Offline Mode: External package downloads are disabled.")
update.packages  <- function(...) message("aaRgh Offline Mode: Package updates are disabled.")
download.file    <- function(...) stop("aaRgh Offline Mode: Network downloads are disabled.")
install_from_swirl <- function(...) message("aaRgh Offline Mode: Courses are pre-installed locally.")
install_course   <- function(...) message("aaRgh Offline Mode: Courses are pre-installed locally.")


# --- SOURCE FILE: options.R ---

# Get path to a lesson
lesson_path <- function(course_name, lesson_name){
  file.path(swirl_courses_dir(), course_name, lesson_name)
}

# Get swirl data file path
swirl_data_dir <- function(){
  sdd <- getOption("swirl_data_dir")
  
  if(is.null(sdd)){
    file.path(find.package("swirl"), "user_data")
  } else {
    sdd
  }
}

# Get swirl courses dir
swirl_courses_dir <- function(){
  scd <- getOption("swirl_courses_dir")
  
  if(is.null(scd)){
    file.path(find.package("swirl"), "Courses")
  } else {
    scd
  }
}

#' Get swirl options
#' 
#' This function is a wrapper for \code{options()} that allows the user to
#' see the state of how certain options for swirl are set up.
#' 
#' @param ... any options can be defined, using name = value.
#' 
#' @export
#' @examples 
#' \dontrun{
#' # See current current swirl options
#' swirl_options()
#' 
#' # Set an option
#' swirl_options(swirl_logging = TRUE)
#' }
swirl_options <- function(...){
  if(length(list(...)) == 0){
    list(
      swirl_courses_dir = getOption("swirl_courses_dir"),
      swirl_data_dir = getOption("swirl_data_dir"),
      swirl_language = getOption("swirl_language"),
      swirl_logging = getOption("swirl_logging"),
      swirl_is_fun = getOption("swirl_is_fun")
    )
  } else {
    options(...)
  }
}

# --- SOURCE FILE: utilities.R ---

swirl_out <- function(..., skip_before=TRUE, skip_after=FALSE) {
  wrapped <- strwrap(str_c(..., sep = " "),
                     width = getOption("width") - 2)
  mes <- str_c("| ", wrapped, collapse = "\n")
  if(skip_before) mes <- paste0("\n", mes)
  if(skip_after) mes <- paste0(mes, "\n")
  Encoding(mes) <- "UTF-8"
  message(mes)
}

# Takes a plain English name and turns it into a more proper 
# file or directory name
make_pathname <- function(name) {
  gsub(" ", "_", str_trim(name))
}

xfer <- function(env1, env2){
  if(length(ls(env1))==0)return()
  lapply(ls(env1), function(var)getAssign(var, env1, env2))
}

getAssign <- function(var, env1, env2){
  assign(var, get(var, env1, inherits=FALSE), envir=env2)
}

cleanAdmin <- function(){
  udat <- file.path(find.package("swirl"), "user_data", "swirladmin")
  file.remove(dir(udat, pattern="*[.]rda", full.names=TRUE))
  invisible()
}

mergeLists <- function(sourceList, destList){
 for (n in names(sourceList)){
   destList[[n]] <- sourceList[[n]]
 }
 return(destList)
}

# Evaluates a user's expression in a clean environment
# whose parent is a snapshot of the previous official 
# environment, i.e., the same environment in which
# the user entered the expression. Any values required
# for evaluation will be found in the snapshot. Any variables
# changed or created by the expression will appear in the 
# clean environment, even if nothing changes in the global. 
#
# For example, if x already has the value c(1, 2, 3) and
# the user enters x <- c(1, 2, 3), nothing will change
# in the global environment, but x with the value c(1, 2, 3)
# will appear in the clean environment.
#
# In case the user's expression involves random numbers, the
# values of variables which appear in the clean environment
# are copied from the global environment.
# 
# For example, if the user enters x <- rnorm(100), then
# evaluating the expression in a clean environment will create
# a variable named x, but it will have a different value
# than that created by the user.
#
safeEval <- function(expr, e){
  e1 <- cleanEnv(e$snapshot)
  ans <- list()
  temp <- capture.output(
    try(suppressMessages(suppressWarnings(eval(expr,e1))), silent=TRUE)
    )
  if(is(temp, "try-error"))return(ans)
  for (x in ls(e1)){
    if(exists(x,globalenv()))
      ans[[x]] <- get(x,globalenv())
  }
  return(ans)
}

# Creates a clean environment whose parent is
# a snapshot of the official environment in an
# earlier state. The snapshot itself is given the
# same parent as the global environment, which will
# consist of loaded namespaces and packages.
#
# Environments in R are subject to reference semantics, 
# i.e., all references refer to the same copy. Hence, 
# the state of an environment cannot be saved for later 
# comparison merely by creating a second reference. Any 
# change in the environment will affect all references. 
# Lists, however, have R's usual copy-on-modify semantics. 
# If snapshot <- as.list(globalenv()), a subsequent change 
# in the global environment will not cause a change in 
# the list (with the exotic exception of environments
# contained in the global environment.)
# 
# Clean environments can be used to detect variables 
# changed or created by a user, as in function safeEval.
# They can also be used to check the correctness of
# a value computed by a user.
#
# For example, if the user enters x <- 2*x, then the
# value of x in the global environment will have changed,
# but if the expression is evaluated in a clean environment
# the value of x on the right will be found in the snapshot
# hence will be the same as that found by the user. 
#
cleanEnv <- function(snapshot){
  # clone of snapshot
  pe <- if(length(snapshot) > 0){
    as.environment(as.list(snapshot))
  } else {
    new.env()  
  }
  parent.env(pe) <- globalenv()
  # return new environment whose parent is pe
  return(new.env(parent=pe))
}


# LESSON PACKAGE DEPENDENCY SUPPORT

# Load lesson package dependencies quietly
loadDependencies <- function(lesson_dir) {
  depends <- file.path(lesson_dir, "dependson.txt")
  if(file.exists(depends)) {
    packages_as_chars <- setdiff(readLines(depends, warn=FALSE), "")
    # If the dependson file is empty, then proceed with lesson
    if(length(packages_as_chars) == 0) return(TRUE)
    swirl_out(s()%N%"Attempting to load lesson dependencies...")
    for(p in packages_as_chars) {
      p <- gsub("^\\s+|\\s+$", "", p) # trim leading and trailing whitespace 
      if(suppressPackageStartupMessages(
        suppressWarnings(
          suppressMessages(require(p, character.only=TRUE, quietly=TRUE))))) {
        swirl_out(s()%N%"Package", sQuote(p), s()%N%"loaded correctly!")
      } else {
        swirl_out(s()%N%"This lesson requires the", sQuote(p), 
                  s()%N%"package. Would you like me to install it for you now?")
        yn <- select.list(choices=c(s()%N%"Yes", s()%N%"No"), graphics=FALSE)
        if(yn == s()%N%"Yes") {
          swirl_out(s()%N%"Trying to install package", sQuote(p), s()%N%"now...")
          install.packages(p, quiet=TRUE)
          if(suppressPackageStartupMessages(
            suppressWarnings(
              suppressMessages(require(p, 
                                       character.only=TRUE, 
                                       quietly=TRUE))))) {
            swirl_out(s()%N%"Package", sQuote(p), s()%N%"loaded correctly!")
          } else {
            swirl_out(s()%N%"Could not install package", paste0(sQuote(p), "!"))
            return(FALSE)
          }
        } else {
          return(FALSE)
        }
      }
    }
  }
  # If loop completes, then print a blank line and return TRUE
  cat("\n")
  return(TRUE)
}

# Execute correct answers for rows 1 through 'up_through' of lesson
complete_part <- function(e) {
  up_through <- e$test_from - 1
  # Get rows though 'up_through' argument
  les <- e$les[seq(up_through), ]
  # Execute previous correct answers in global env
  exec_cmd <- function(row) {
    if(row['Class'] == "cmd_question") {
      eval(parse(text = row['CorrectAnswer']), envir=globalenv())
    } else if(row['Class'] == "script") {
      orig_script_name <- row['Script']
      correct_script_name <- paste0(
        tools::file_path_sans_ext(orig_script_name), "-correct.R")
      correct_script_path <- file.path(e$path, "scripts", 
                                       correct_script_name)
      if(file.exists(correct_script_path)) {
        try(source(correct_script_path))
      } else {
        stop("Correct script not found at ", correct_script_path)
      }
    }
  }
  message("Completing the first part of the lesson for you...\n")
  apply(les, 1, exec_cmd)
  invisible()
}

# --- SOURCE FILE: languages.R ---

swirl_language <- function(){
  lang <- getOption("swirl_language")
  langs <- c("chinese_simplified", "dutch", "english", 
             "french", "german", "german_formal", "korean", "portuguese", 
             "spanish", "turkish")
  
  if(is.null(lang) || !(lang %in% langs)){
    "english"
  } else {
    lang
  }
}

#' Select a language
#' 
#' Select a language for swirl's menus.
#' @param language The language that swirl's menus will use.
#' This must be one of the following values: \code{"chinese_simplified"}.
#' \code{"english"}, \code{"french"}, \code{"german"},
#' \code{"korean"}, \code{"spanish"}, or \code{"turkish"}.
#' If \code{NULL} the user will be asked to choose a language
#' interactively. The default value is \code{NULL}.
#' @param append_rprofile If \code{TRUE} this command will append 
#' \code{options(swirl_language = [selected language])} to the end of your 
#' Rprofile. The default value is \code{FALSE}.
#' 
#' @export
select_language <- function(language = NULL, append_rprofile = FALSE){
  langs <- c("chinese_simplified", "dutch", "english", 
             "french", "german", "german_formal", "korean", "portuguese", 
             "spanish", "turkish")
  if(is.null(language)){
    selection <- select.list(langs)
  } else if(!(language %in% langs)){
    stop("Invalid value for 'language.'")
  } else {
    selection <- language
  }
  
  options(swirl_language = selection)
  
  if(append_rprofile){
    opts <- paste0("options(swirl_language = '", selection, "')")
    cat(opts, "\n", file = file.path("~", ".Rprofile"), append = TRUE)
  }
}

# set working directory to swirl repo before using
#' @importFrom yaml yaml.load_file
compile_languages <- function(){
  ctime <- as.integer(Sys.time())
  clone_dir <- file.path(tempdir(), ctime)
  dir.create(clone_dir, showWarnings = FALSE)
  git_clone <- paste("git clone https://github.com/swirldev/translations.git", clone_dir)
  system(git_clone)
  
  menus_dir <- file.path(clone_dir, "menus")
  menus <- list.files(menus_dir, pattern = "yaml$", full.names = TRUE)
  
  for(i in menus){
    lang_name <- sub(".yaml$", "", basename(i))
    cmd <- paste0(lang_name, " <- swirl:::wrap_encoding(yaml.load_file('", i, "'))")
    eval(parse(text=cmd))
  }
  
  comma_sep_langs <- paste(sub(".yaml$", "", basename(menus)), collapse = ", ")
  cmd <- paste0("save(", comma_sep_langs, ", file = file.path('R', 'sysdata.rda'))")
  eval(parse(text=cmd))
  unlink(clone_dir, recursive = TRUE, force = TRUE)
}

"%N%" <- function(f, y){
  result <- f(y)
  if(is.null(result)){
    y
  } else {
    result
  }
}

s <- function(){
  s_helper
}

s_helper <- function(x){
  cmd <- paste0(swirl_language(), "$`", x, "`")
  tryCatch(eval(parse(text=cmd)),
    warning = function(c) NULL
  )
}

# set working directory to swirl repo before using
# make sure the global env is clear before using

#' @importFrom stringr str_match
check_strings <- function(){
  load(file.path("R", "sysdata.rda"))
  langs <- ls()
  ##langs <- "english"
  
  for(i in list.files("R", pattern = "\\.R$")){
    source_code <- readLines(file.path("R", i), warn = FALSE)
    strings <- grep("s\\(\\)%N%", source_code)
    for(j in strings){
      for(l in langs){
        if(!(str_match(source_code[j], '"(.*?)"')[,2] %in% eval(parse(text = paste0("names(", l, ")"))))){
          message(l, " : '", str_match(source_code[j], '"(.*?)"')[,2], "' : ", i)
          ##cat('"', str_match(source_code[j], '"(.*?)"')[,2], '"', ':\n "', str_match(source_code[j], '"(.*?)"')[,2], '"\n\n',  sep = "")
        }
      }
    }
  }
}

# --- SOURCE FILE: phrases.R ---

# Return random praise.
praise <- function() {
  swirl_is_fun <- getOption("swirl_is_fun")
  
  if(is.null(swirl_is_fun) || isTRUE(swirl_is_fun)) {
    phrases <- c(s()%N%"You got it!",
                 s()%N%"Nice work!",
                 s()%N%"Keep up the great work!",
                 s()%N%"You are doing so well!",
                 s()%N%"All that hard work is paying off!",
                 s()%N%"You nailed it! Good job!",
                 s()%N%"You're the best!",
                 s()%N%"You are amazing!",
                 s()%N%"Keep working like that and you'll get there!",
                 s()%N%"Perseverance, that's the answer.",
                 s()%N%"Great job!",
                 s()%N%"You are quite good my friend!",
                 s()%N%"Your dedication is inspiring!",
                 s()%N%"You got it right!",
                 s()%N%"That's correct!",
                 s()%N%"You are really on a roll!",
                 s()%N%"Excellent job!",
                 s()%N%"All that practice is paying off!",
                 s()%N%"Excellent work!",
                 s()%N%"That's a job well done!",
                 s()%N%"That's the answer I was looking for.")
  } else {
    phrases <- s()%N%"Correct!"
  }
  sample(phrases, 1)
}

# Return random "try again" message.
tryAgain <- function() {
  swirl_is_fun <- getOption("swirl_is_fun")
  
  if(is.null(swirl_is_fun) || isTRUE(swirl_is_fun)) {
    phrases <- c(s()%N%"Almost! Try again.",
                 s()%N%"You almost had it, but not quite. Try again.",
                 s()%N%"Give it another try.",
                 s()%N%"Not quite! Try again.",
                 s()%N%"Not exactly. Give it another go.",
                 s()%N%"That's not exactly what I'm looking for. Try again.",
                 s()%N%"Nice try, but that's not exactly what I was hoping for. Try again.",
                 s()%N%"Keep trying!",
                 s()%N%"That's not the answer I was looking for, but try again.",
                 s()%N%"Not quite right, but keep trying.",
                 s()%N%"You're close...I can feel it! Try it again.",
                 s()%N%"One more time. You can do it!",
                 s()%N%"Not quite, but you're learning! Try again.",
                 s()%N%"Try again. Getting it right on the first try is boring anyway!")
  } else {
    phrases <- s()%N%"Incorrect. Please try again."
  }
  sample(phrases, 1)
}

# --- SOURCE FILE: answerTests.R ---

# Extensible testing
# 
# If tests are to be identified by keyphrases, then keyphrases must somehow be
# converted (i.e., parsed) to function calls. It is reasonable to anticipate
# that new tests will arise with broad deployment and new course material. 
# Thus it would be convenient if new tests and keyphrases could be added 
# without the need to change core swirl source code. 
# 
# Tests themselves would be new functions or methods, hence are additional code
# by nature. The problem is to extensibly parse keyphrases to function calls.
# One possibility, illustrated below, is to give new tests themselves
# primary responsibility for parsing their own keyphrases.
# 
# The tests themselves are identified by the substrings before the "=".
# Substrings after "=" are essentially arguments. To illustrate a possiblity
# we'll have core code base its function call on the string prior to "=",
# and leave the rest to tests themselves. It is doubtful this scheme would
# be flexible enough in general.
# 
# There are various ways to do it, but we'll use S3 methods because we're
# using them for other things as well. We'll give the keyphrase a class
# attribute corresponding to the substring prior to "=", and use the keyphrase
# as first argument to the method.


runTest <- function(...)UseMethod("runTest")

# Always returns FALSE. If the default test in invoked, something is wrong.
runTest.default <- function(...)return(FALSE)

# Always returns TRUE, for development purposes.
runTest.true <- function(...)return(TRUE)

# Returns TRUE if e$expr is an assignment 
# 
runTest.assign <- function(keyphrase, e) {
  identical(class(e$expr), "<-")
}

# Returns TRUE if the function to the right of = in the keyphrase has
# been used in e$expr
#  
runTest.useFunc <- function(keyphrase, e) {
  func <- rightside(keyphrase)
  (is.call(e$expr) || is.expression(e$expr)) &&
    func %in% flatten(e$expr)
}

# Returns TRUE if as.character(e$val) matches the string to the right
# of "=" in keyphase
# This is for single word answers
runTest.word <- function(keyphrase, e) {
  correctVal <- str_trim(rightside(keyphrase))
  identical(str_trim(as.character(e$val)), 
            str_trim(as.character(correctVal)))
}
# Returns TRUE if as.character(e$val) matches the string to the right
# of "=" in keyphase
# This is for multi-word answers for which order matters
runTest.word_order <- function(keyphrase, e) {
  correctVal <- str_trim(rightside(keyphrase))
  correct_list <- str_trim(unlist(strsplit(correctVal,",")))
  userAns <- str_trim(unlist(strsplit(as.character(e$val),",")))
  identical(userAns, correct_list)
}
# Returns TRUE if as.character(e$val) matches the string to the right
# of "=" in keyphase
# This is for multi-word answers for which order doesn't matter
runTest.word_many <- function(keyphrase,e){
  correct_ans <- rightside(keyphrase)
  correct_list <- str_trim(unlist(strsplit(correct_ans,",")))
  identical(sort(correct_list), sort(e$val))
}

# Tests if the user has just created one new variable. If so, assigns 
# e$newVar its value and returns TRUE.
runTest.newVar <- function(keyphrase, e){
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  delta <- if(!customTests$AUTO_DETECT_NEWVAR){
    safeEval(e$expr, e)
  } else {
    e$delta
  }
  if (length(delta)==1){
    e$newVar <- delta[[1]]
    e$newVarName <- names(delta)[1]
    e$delta <- mergeLists(delta, e$delta)
    return(TRUE)
  }
  else {
    return(FALSE)
  }
}

# Tests if the user has just created one new variable of correct name. If so, 
# returns TRUE.
# keyphrase: correctName=<correct name>
runTest.correctName <- function(keyphrase, e){
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  delta <- if(!customTests$AUTO_DETECT_NEWVAR){
    safeEval(e$expr, e)
  } else {
    e$delta
  }
  correctName <- rightside(keyphrase)
  if ((length(delta)==1) && (identical(names(delta)[1],correctName))) {
    e$newVar <- delta[[1]]
    e$newVarName <- names(delta)[1]
    e$delta <- mergeLists(delta, e$delta)
    return(TRUE)
  }
  else {
    return(FALSE)
  }
 }

# Tests the result of a computation such as mean(newVar) applied
# to a specific variable created in a previous question. 
runTest.result <- function(keyphrase, e){
  correct.expr <- parse(text=rightside(keyphrase))
  newVar <- e$newVar
  ans <- all.equal(e$val, eval(correct.expr))
  # all.equal may return a diagnostic string
  return(ifelse(is.logical(ans), ans, FALSE))
}

runTest.exact <- function(keyphrase,e){
  is.correct <- FALSE
  if(is.numeric(e$val)){
    correct.ans <- eval(parse(text=rightside(keyphrase)))
    epsilon <- 0.01*abs(correct.ans)
    is.correct <- abs(e$val-correct.ans) <= epsilon
  }
  return(is.correct)
}

runTest.range <- function(keyphrase,e){
  is.correct <- FALSE
  correct.ans <-parse(text=rightside(keyphrase))
  if (is.numeric(e$val)){
     correct.ans <- as.character(correct.ans)
     temp <- str_split(correct.ans,"-")
     temp <- as.numeric(unlist(str_split(correct.ans,"-")))
     # use is.logical in case the user types a non-digit which converts to NA's
     is.correct <- (e$val >= temp[1] && e$val <= temp[2])
  }
  return(is.correct)
}

runTest.newcmd <- function(keyphrase,e){
  correct.expr <- parse(text=rightside(keyphrase))[[1]]
  correct.ans  <- eval(correct.expr)
  ansResults <- expectThat(e$val,
                               equals_legacy(correct.ans,label=correct.ans),
                               label=e$val)
  callResults <- expectThat(as.expression(e$expr)[[1]],
                                is_identical_to_legacy(correct.expr,label=deparse(correct.expr)),
                                label=deparse(e$expr))
    
 #   identical(as.expression(e$expr)[[1]], as.expression(correct.expr)[[1]])
  if(ansResults$passed && callResults$passed){
    return(TRUE)
  } else  
    if (ansResults$passed && !callResults$passed){
      swirl_out("That's not the expression I expected but it works.")
      swirl_out(callResults$message)
      #todo
      #following line is temporary fix to create correct vars for future ques if needed
      eval(correct.expr,globalenv())
      return(TRUE)
    }
  else
    return(FALSE)
}

runTest.swirl1cmd <- function(keyphrase,e){
  correct.expr <- parse(text=rightside(keyphrase))
  correct.ans  <- eval(correct.expr)
  ans.is.correct <- isTRUE(all.equal(correct.ans, e$val))
  call.is.correct <- identical(as.expression(e$expr)[[1]], as.expression(correct.expr)[[1]])
  if(ans.is.correct && call.is.correct){
    return(TRUE)
  } else  
    if (ans.is.correct && !call.is.correct){
     swirl_out("That's not the expression I expected but it works.")
      #following line is temporary fix to create correct vars for future ques if needed
      eval(correct.expr,globalenv())
      return(TRUE)
    }
  else
    return(FALSE)
}

runTest.trick <- function(keyphrase,e){
 if (exists("trick",e,inherits=FALSE)){
   rm("trick",envir=e,inherits=FALSE)
   return(TRUE)
 }
 else{
   e$trick <- 1
   return(FALSE)
 } 
}

## TESTS AND KEYPHRASES BASED ON PACKAGE TESTTHAT
# These tests will print diagnostics in "dev" mode
# but not in user (default) mode.

# Returns TRUE if e$var or (if it exists) the given 
# global variable is of the given class
# keyphrase: is_a=class or is_a=class,variable
runTest.is_a <- function(keyphrase, e) {
  temp <- strsplit(rightside(keyphrase),",")[[1]]
  class <-  str_trim(temp[1])
  variable <- str_trim(temp[2])
  if(!is.na(variable) && exists(variable, globalenv())){
    val <- get(variable, globalenv())
  } else {
    val <- e$val
  }
  label <- val
  results <- expectThat(val, is_a_legacy(class), label=label)
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# Returns TRUE if the function to the right of = in the keyphrase has
# been used in e$expr
# keyphrase: uses_func=functionName
runTest.uses_func <- function(keyphrase, e) {
  func <- rightside(keyphrase)
  results <- expectThat(e$expr,
                        uses_func(func, label=func), 
                        label=deparse(e$expr))
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# Returns TRUE if as.character(e$val) matches the string to the right
# of "=" in keyphase
# keyphrase: matches=regularExpresion
runTest.matches <- function(keyphrase, e) {
  correctVal <- tolower(str_trim(rightside(keyphrase)))
  userVal <- str_trim(as.character(e$val))
  results <- expectThat(tolower(userVal), 
                        matches_legacy(correctVal), 
                        label=userVal)
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# Tests if the user has just created one new variable (of correct name
# if given.) If so, returns TRUE.
# keyphrase: creates_var or creates_var=correctName
runTest.creates_var <- function(keyphrase, e){
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  delta <- if(!customTests$AUTO_DETECT_NEWVAR){
    safeEval(e$expr, e)
  } else {
    e$delta
  }
  correctName <- rightside(keyphrase)
  if(is.na(correctName)){
    results <- expectThat(length(delta), equals_legacy(1), 
                          label=paste(deparse(e$expr), 
                                      "does not create a variable."))
  } else {
    results <- expectThat(names(delta), 
                          is_equivalent_to_legacy(correctName, label=correctName), 
                          label=paste(deparse(e$expr),
                                      "does not create a variable named",
                                      correctName))
  }
  if(results$passed){
    e$newVar <- e$val
    e$newVarName <- names(delta)[1]
    e$delta <- mergeLists(delta, e$delta)
  } else if(is(e,"dev")){
    swirl_out(results$message)
  }
  return(results$passed)
}

# Tests the result of a computation such as mean(newVar) applied
# to a specific variable created in a previous question.
# keyphrase: equals=correctExpression,variable 
runTest.equals <- function(keyphrase, e){
  temp <- strsplit(rightside(keyphrase),",")[[1]]
  correctExprLabel <- temp[1]
  variable <- str_trim(temp[2])
  correctExpr <- gsub(variable, paste0("e$",variable), correctExprLabel)
  correctAns <- safeEval(parse(text=correctExpr))
  if(length(correctAns) != 1)return(FALSE)
  results <- expectThat(e$var, 
                        equals_legacy(correctAns[[1]], 
                               label=correctExprLabel), 
                        label=deparse(e$expr))
  if(is(e, "dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# Returns TRUE if as.expression
# (e$expr) matches the expression indicated to the right
# of "=" in keyphrase
# keyphrase:equivalent=expression
runTest.equivalent <- function(keyphrase,e) {
  correctExpr <- as.list(parse(text=rightside(keyphrase)))
  userExpr <- as.list(as.expression(e$expr))
  results <- expectThat(userExpr,
                        is_equivalent_to_legacy(correctExpr,deparse(correctExpr)),
                        label=deparse(userExpr))
                        
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}



# Tests that a value just entered at the R prompt is within
# the given range
# keyphrase: in_range=a,b
runTest.in_range <- function(keyphrase, e){
  range <- try(eval(parse(text=paste0("c(", rightside(keyphrase), ")"))),
               silent=TRUE)
  if(!is.numeric(range)){
    swirl_out(paste("The given range", rightside(keyphrase), "is not numeric."))
    return(FALSE)
  }
  results <- expectThat(e$var, 
                        in_range(range, 
                                 label=range), 
                        label=e$var)
  if(is(e, "dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# Test that the user has entered an expression identical to that
# given in the keyphrase.
# keyphrase: "expr_identical=<correct expression>"
runTest.expr_identical <- function(keyphrase, e){
  correct <- parse(text=rightside(keyphrase))[[1]]
  expr <- e$expr
  if(is.expression(expr))expr <- expr[[1]]
  results <- expectThat(expr, 
                        is_identical_to_legacy(correct, label=rightside(keyphrase)),
                        label=deparse(expr))
  if( is(e, "dev") && !results$passed)swirl_out(results$message) 
  return(results$passed)
}

# Test the the length of e$val is that given in the keyphrase
# keyphrase: "val_length=<integer>"
runTest.val_length <- function(keyphrase, e){
  try(n <- as.integer(rightside(keyphrase)), silent=TRUE)
  if(is.na(n)){
    stop(message=paste("BUG: right side of", keyphrase,
                                 "is not an integer."))
  }
  results <- expectThat(length(e$val), equals_legacy(n, label=n), 
                        label=paste0("length(c(", toString(e$val), "))"))                                                   
  if( is(e, "dev") && !results$passed)swirl_out(results$message) 
  return(results$passed)
}

### HELPER FUNCTIONS

rightside <- function(keyphrase){
  n <- str_locate(keyphrase,"=")[1]
  return(substr(keyphrase,n+1,nchar(keyphrase)))
}


flatten <- function(expr){
  if(is.leaff(expr)){
    return(expr)
  } else {
    return(unlist(lapply(expr, flatten)))
  }
}

is.leaff <- function(x)!(is.call(x) || is.expression(x))


### TESTTHAT FUNCTIONS CUSTOMIZED FOR ANSWERTESTS

findExpr <- function(name, env = parent.frame()){
  subs <- do.call("substitute", list(as.name(name), env))
  str_c(deparse(subs, width.cutoff = 500), collapse = "\n")
}

expectThat <- function(object, condition, info=NULL, label=NULL){
  if (is.null(label)) {
    label <- findExpr("object")
  }
  results <- swirlExpectation(condition(object))
  results$message <- str_c(label, " ", results$message)
  if (!is.null(info)) {
    results$message <- str_c(results$message, "\n", info)
  }
  return(results)
}

# Patch for slight incompatibility of testthat versions
swirlExpectation <- function(testthat_expectation){
  passed <- testthat_expectation$passed
  error <- testthat_expectation$error
  if(exists("failure_msg", testthat_expectation)){
    message <- failure_msg <- testthat_expectation$failure_msg
    success_msg <- testthat_expectation$success_msg
  } else {
    failure_msg <- message <- testthat_expectation$message
    success_msg <- "unknown"
  }
  structure(
    list(
      passed = passed, error = error, message = message,
      failure_msg = failure_msg, success_msg = success_msg
    ),
    class = c("swirl_expectation", "expectation")
  )
}


## CUSTOM EXPECTATIONS FOR ANSWER TESTS 

uses_func <- function(expected, label = NULL, ...){
  if(is.null(label)){
    label <- findExpr("expected")
  }else if (!is.character(label) || length(label) != 1) {
    label <- deparse(label)
  }
  function(expr){
    uses <- (is.call(expr) || is.expression(expr)) && 
      expected %in% flatten(expr)
    expectation_legacy(identical(uses, TRUE),
                str_c("does not use ", label))
  }
}

in_range <- function(range, label=NULL){
  range <- sort(range)
  function(number){
    isOK <- is.numeric(number) && 
      isTRUE(number >= range[1]) && 
      isTRUE(number <= range[2])
    expectation_legacy(identical(isOK, TRUE), 
                str_c("is not between ", range[1], " and ", range[2]))
  }
}

# --- SOURCE FILE: answerTests2.R ---

#' Answer Tests
#'
#' Answer tests are how swirl determines whether a user has answered
#' a question correctly or not. Each question has one or more answer
#' tests associated with it, all of which must be satisfied in order for
#' a user's response to be considered correct. As the instructor, you 
#' can specify any combination of our predefined answer tests or create your
#' own custom answer tests to suit your specific needs. This document will
#' explain your options.
#' 
#' @name AnswerTests
#' 
#' @details
#' For each question that you author as part of a swirl lesson, you 
#' must specify exactly one \emph{correct answer}. This is separate and
#' distinct from the answer tests. This does not have to be
#' the only correct answer, but it must answer the question correctly. 
#' If a user \code{\link{skip}}s your question, this is the answer that will be
#' entered on his or her behalf.
#' 
#' If you're using the \href{https://github.com/swirldev/swirlify}{swirlify}
#' authoring tool, the correct answer will
#' be automatically translated into the appropriate answer test for most
#' question types. Questions that require the user to enter a valid
#' command at the R prompt (which we'll refer to as \emph{command questions})
#' are the only exception. Since there are often many possible ways to
#' answer a command question, you must determine how you'd like swirl to
#' assess the correctness of a user's response. This is where answer
#' tests come in.
#' 
#' You can specify any number of answer tests. If you use more than one, you
#' must separate them with semicolons. If you do not specify any answer tests
#' for a command question, then the default test will be used. The default
#' test is \code{omnitest(correctExpr='<correct_answer_here>')}, which will 
#' simply check that the user's expression matches the expression that you 
#' provided as a correct answer. 
#' 
#' In many cases, the default answer test will provide sufficient vetting of
#' a user's response to a command question. While it is somewhat restrictive
#' in the sense that it requires an exact match of expressions (ignoring 
#' whitespace), it is liberating to the course author for two reasons.
#' \enumerate{
#'   \item It allows for fast prototyping of content. As you're developing
#'   content, you may find that determining how to test for correctness
#'   distracts you from the message you're trying to communicate. 
#'   \item You don't have to worry about what happens if the user enters 
#'   an incorrect response, but is allowed to proceed because of an oversight
#'   in the answer tests. Since swirl sessions are continuous, accepting
#'   an incorrect answer early in a lesson can cause problems later on. By
#'   using the default answer test, you eliminate this burden by requiring an
#'   exact match of expressions and hence not allowing the user to advance
#'   until you are certain they've entered the correct response.
#' }
#'  
#' It's important to keep in mind that as your content matures, you can always 
#' go back and make your answer testing strategy more elaborate. The main
#' benefit of using tests other than the default is that the user will not be
#' required to enter an expression exactly the way you've specified it. He or
#' she will have more freedom in terms of how they respond to a question, as
#' long as they satisfy the conditions that you see as being most important.
#' 
#' @section Predefined Answer Tests:
#' Each of the predefined answer tests listed below has
#' its own help file, where you'll find more detailed explanations and
#' examples.
#' 
#' \code{\link{any_of_exprs}}: Test that the user's expression matches any of several possible expressions.
#'
#' \code{\link{calculates_same_value}}: Test that the user's expression evaluates to a certain value.
#' 
#' \code{\link{expr_creates_var}}: Test that a new variable has been created.
#' 
#' \code{\link{expr_identical_to}}: Test that the user has entered a particular expression.
#' 
#' \code{\link{expr_is_a}}: Test that the expression itself is of a specific \code{\link{class}}.
#' 
#' \code{\link{expr_uses_func}}: Test that a particular function has been used.
#' 
#' \code{\link{func_of_newvar_equals}}: Test the result of a computation such as \code{mean(newVar)} applied to a specific (user-named) variable created in a previous question.
#' 
#' \code{\link{omnitest}}: Test for a correct expression, a correct value, or both.
#' 
#' \code{\link{val_has_length}}: Test that the value of the expression has a particular \code{\link{length}}.
#' 
#' \code{\link{val_matches}}: Test that the user's expression matches a regular expression (\code{\link{regex}}).
#' 
#' \code{\link{var_is_a}}: Test that the \emph{value} of the expression is of a specific \code{\link{class}}.
#' 
#' @section Custom Answer Tests:
#' Occasionally, you may want to test something that is outside the scope of
#' our predefined answer tests. Fortunately, this is very easy to do. If you
#' are using the swirlify authoring tool, then a file called
#' \code{customTests.R} (case-sensitive) is automatically created in the lesson
#' directory. If it's not there already, you can create the file manually.
#' 
#' In this file, you can write your own answer tests. These answer tests are 
#' then available to you just the same as any of the standard tests. However, 
#' the scope of a custom answer test is limited to the lesson within which 
#' you've defined it.
#' 
#' Each custom answer test is simply an R function that follows a few 
#' basic rules:
#' \enumerate{
#'   \item Give the function a distinct name that will help you remember what
#'   is does (e.g. \code{creates_matrix_with_n_rows}).
#'   \item The first line of the function body is 
#'   \code{e <- get("e", parent.frame())}, which gives you access to the 
#'   environment \code{e}. Any important information, such as the expression
#'   typed by the user, will be available to you through \code{e}.
#'   \item Access the expression entered by the user with \code{e$expr} and 
#'   the value of the expression with \code{e$val}. 
#'   Note that \code{e$expr} comes in
#'   the form of an unevaluated R \code{\link{expression}}.
#'   \item The function returns \code{TRUE} if the test is passed and
#'   \code{FALSE} otherwise. You should be careful that no other
#'   value could be returned (e.g. \code{NA}, \code{NULL}, etc.)
#'   }
#' 
#' @family AnswerTests
NULL
 
#' Test for a correct expression, a correct value, or both.
#' 
#' Omnitest can test for a correct expression, a correct value,
#' or both. In the case of values it is limited to testing for 
#' character or numeric vectors of length 1.
#' @param correctExpr the correct or expected expression as a string
#' @param correctVal the correct value (numeric or character)
#' @param strict a logical value indicating that the expression should be as expected even if the value is correct. If \code{FALSE} (the default) a correct value will pass the test even if the expression is not as expected, but a notification will be issued.
#' @param eval_for_class a logical value. If TRUE, evaluate the first argument of an S3 method to determine its class. Default=TRUE. Global value may also be set as customTests$EVAL_FOR_CLASS.
#' @examples
#' \dontrun{
#' 
#'   # Test that a user has chosen a correct menu item
#'   #
#'   omnitest(correctVal='Men in a college dorm.')
#'    
#'   # Test that a user has entered a correct number at the
#'   # command line
#'   #
#'   omnitest(correctVal=19)
#'    
#'   # Test that a user has entered a particular command
#'   #
#'   omnitest('myVar <- c(3, 5, 7)')
#'    
#'   # Test that a user has entered a command which computes
#'   # a specific value but perhaps in a different manner 
#'   # than anticipated
#'   #
#'   omnitest('sd(x)^2', 5.95)
#'   #
#'   # If the user enters sd(x)*sd(x), rather than sd(x)^2, a notification
#'   # will be issued, but the test will not fail.
#'   
#'   # Test that a user has entered a command which computes
#'   # a specific value in a particular way
#'   #
#'   omnitest('sd(x)^2', 5.95, strict=TRUE)
#'   #
#'   # In this case, if the user enters sd(x)*sd(x) the test will fail.
#'   
#'   }
#' @family AnswerTests
omnitest <- function(correctExpr=NULL, correctVal=NULL, strict=FALSE, eval_for_class=as.logical(NA)){
  e <- get("e", parent.frame())
  # Trivial case
  if(is.null(correctExpr) && is.null(correctVal))return(TRUE)
  # If eval_for_class is not specified, default to customTests$EVAL_FOR_CLASS.
  # If the latter is not set, default to TRUE.
  if(is.na(eval_for_class)){
    if(exists("EVAL_FOR_CLASS", customTests)){
       eval_for_class <- isTRUE(customTests$EVAL_FOR_CLASS)
    } else {
      eval_for_class <- TRUE
    }
  }
  # If eval_for_class is TRUE, create a parent environment for that in
  # in which evaluations for class are to be made.
  eval_env <- if(eval_for_class){
    cleanEnv(e$snapshot)
  } else {
    NULL
  }
  # Testing for correct expression only
  if(!is.null(correctExpr) && is.null(correctVal)){
    err <- try({
      good_expr <- parse(text=correctExpr)[[1]]
      ans <- is_robust_match(good_expr, e$expr, eval_for_class, eval_env)
    }, silent=TRUE)
    if (is(err, "try-error")) {
      return(expr_identical_to(correctExpr))
    } else {
      return(ans)
    }
  }
  # Testing for both correct expression and correct value
  # Value must be character or single number
  valGood <- as.logical(NA)
  if(!is.null(correctVal)){
    if(is.character(e$val)){
      valResults <- expectThat(e$val,
                               is_equivalent_to_legacy(correctVal, label=correctVal),
                               label=(e$val))
      if(is(e, "dev") && !valResults$passed)swirl_out(valResults$message)
      valGood <- valResults$passed
      # valGood <- val_matches(correctVal)
    } else if(!is.na(e$val) && is.numeric(e$val) && length(e$val) == 1){
      cval <- try(as.numeric(correctVal), silent=TRUE)
      valResults <- expectThat(e$val, 
                            equals_legacy(cval, label=correctVal),
                            label=toString(e$val))
      if(is(e, "dev") && !valResults$passed)swirl_out(valResults$message)
      valGood <- valResults$passed
    }
  }
  # If a correct expression is given attempt a robust match with user's expression.
  exprGood <- TRUE
  if(!is.null(correctExpr)){
    err <- try({
      good_expr <- parse(text=correctExpr)[[1]]
      ans <- is_robust_match(good_expr, e$expr, eval_for_class, eval_env)
    }, silent=TRUE)
    exprGood <- ifelse(is(err, "try-error"), expr_identical_to(correctExpr), ans)
  }
  if((isTRUE(valGood) || is.na(valGood)) && exprGood){
    return(TRUE)
  } else if (isTRUE(valGood) && !exprGood && !strict){
      swirl_out(s()%N%"That's not the expression I expected but it works.")
      swirl_out(s()%N%"I've executed the correct expression in case the result is needed in an upcoming question.")
      eval(parse(text=correctExpr),globalenv())
      return(TRUE)
    } else {
      return(FALSE)
    }
}

#' Test that the user has entered a particular expression.
#' 
#' Test that the user has entered an expression identical to that
#' given as the first argument.
#' @param correct_expression the correct or expected expression as a string
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#'   # Test that a user has entered a particular command
#'   #
#'   expr_identical_to('myVar <- c(3, 5, 7)')
#' }
#' @family AnswerTests
expr_identical_to <- function(correct_expression){
  e <- get("e", parent.frame())
  expr <- e$expr
  if(is.expression(expr))expr <- expr[[1]]
  correct <- parse(text=correct_expression)[[1]]
  results <- expectThat(expr, 
                        is_identical_to_legacy(correct, label=correct_expression),
                        label=deparse(expr))
  if( is(e, "dev") && !results$passed)swirl_out(results$message) 
  return(results$passed)
}

#' Test that the user's expression evaluates to a certain value.
#'
#' Test that the value calculated by the user's expression is the same as the
#' value calculated by the given expression.
#' @param expression An expression whose value will be compared to the value
#' of the user's expression.
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#'   # Test that a user's expression evaluates to a certain value
#'   #
#'   calculates_same_value('matrix(1:20, nrow=4, ncol=5)')
#' }
#' @family AnswerTests
calculates_same_value <- function(expression){
  e <- get("e", parent.frame())
  # Calculate what the user should have done.
  eSnap <- cleanEnv(e$snapshot)
  val <- eval(parse(text=expression), eSnap)
  passed <- isTRUE(all.equal(val, e$val))
  if(!passed)e$delta <- list()
  return(passed)
}

#' Test that the user's expression matches a regular expression.
#' 
#' Returns \code{TRUE} if \code{as.character(e$val)} matches the regular
#' expression given as the first argument.
#' @param regular_expression a regular expression which user value should match
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#'   # Test that a user has entered a value matching
#'   # '[Cc]ollege [Ss]tudents' or has selected it 
#'   # in a multiple choice question.
#'   #
#'   val_matches('[Cc]ollege [Ss]tudents')
#' }
#' @family AnswerTests
val_matches <- function(regular_expression) {
  e <- get("e", parent.frame())
  userVal <- str_trim(as.character(e$val))
  results <- expectThat(userVal, 
                        matches_legacy(regular_expression), 
                        label=userVal)
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

#' Test that the user has entered one of several possible expressions.
#' 
#' Returns \code{TRUE} if the expression the user has entered
#' matches any of the expressions given (as character strings) in 
#' the argument.
#' @param ... any number of expressions, as character strings
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' 
#' # Test that a user has entered either cor(x, y) or cor(y, x)
#' any_of_exprs('cor(x, y)', 'cor(y, x)')
#' }
#' @family AnswerTests
any_of_exprs <- function(...){
  e <- get("e", parent.frame())
  any(sapply(c(...), function(expr) omnitest(expr)))
}

#' Test that the value of the expression is of a specific class.
#' 
#' Returns \code{TRUE} if a variable of the given name exists
#' in the global environment and is of the given class.
#' @param class expected class which the given variable
#' @param var_name name of the variable
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test that a variable named "x" in the global environmentis numeric.
#' var_is_a('numeric', 'x')
#' }
#' @family AnswerTests
var_is_a <- function(class, var_name) {
  e <- get("e", parent.frame())
  class <-  str_trim(class)
  var_name <- str_trim(var_name)
  if(exists(var_name, globalenv())){
    val <- get(var_name, globalenv())
    label <- val
    results <- expectThat(val, is_a_legacy(class), label=label)
    if(is(e,"dev") && !results$passed)swirl_out(results$message)
    return(results$passed)
  } else {
    if(is(e,"dev"))swirl_out(paste(var_name, "does not exist."))
    return(FALSE)
  }
}

#' Test that the expression itself is of a specific \code{class}.
#' 
#' Returns \code{TRUE} if \code{e$expr} is of the given \code{\link{class}}.
#' @param class expected \code{class} of the given expression
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test if the expression entered by a user is an assignment
#' #
#' expr_is_a('<-')
#' }
#' @family AnswerTests
expr_is_a <- function(class) {
  e <- get("e", parent.frame())
  class <-  str_trim(class)
  expr <- e$expr
  label <- deparse(e$expr)
  results <- expectThat(expr, is_a_legacy(class), label=label)
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

#' Test that a particular function has been used.
#' 
#' Returns \code{TRUE} if the \code{e$expr} uses the function whose
#' name is given as the first argument.
#' @param func name of the function expected to be used
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test that the user has entered an expression using sd()
#' #
#' expr_uses_func('sd')
#' }
#' @family AnswerTests
expr_uses_func <- function(func) {
  e <- get("e", parent.frame())
  func <- str_trim(func)
  results <- expectThat(e$expr,
                        uses_func(func, label=func), 
                        label=deparse(e$expr))
  if(is(e,"dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

#' Test that a new variable has been created.
#' 
#' Tests if the \code{e$expr} creates one new variable (of correct name
#' if given.) If so, returns \code{TRUE}.
#' @param correctName expected name of the new variable or \code{NULL}
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test if the user has entered an expression which creates
#' # a new variable of any name.
#' expr_creates_var()
#' #
#' # Test if the user has entered an expression which creates
#' # a variable named 'myNum'
#' #
#' expr_creates_var('myNum')
#' }
#' @family AnswerTests
expr_creates_var <- function(correctName=NULL){
  e <- get("e", parent.frame())
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  delta <- if(!customTests$AUTO_DETECT_NEWVAR){
    safeEval(e$expr, e)
  } else {
    e$delta
  }
  if(is.null(correctName)){
    results <- expectThat(length(delta), equals_legacy(1), 
                          label=paste(deparse(e$expr), 
                                      "does not create a variable."))  
  } else {
    results <- expectThat(names(delta), 
                          is_equivalent_to_legacy(correctName, label=correctName), 
                          label=paste(deparse(e$expr),
                                      "does not create a variable named",
                                      correctName))
  }
  if(results$passed){
    e$newVar <- e$val
    e$newVarName <- names(delta)[1]
    e$delta <- mergeLists(delta, e$delta)
  } else if(is(e,"dev")){
    swirl_out(results$message)
  }
  return(results$passed)
}

#' Test that the value of the expression has a particular \code{length}.
#' 
#' Test the the \code{\link{length}} of \code{e$val} is that given by the 
#' first argument.
#' @param len expected length of the variable created by a user
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test that the user has created a varible of length 10
#' #
#' val_has_length(10)
#' }
#' @family AnswerTests
val_has_length <- function(len){
  e <- get("e", parent.frame())
  try(n <- as.integer(len), silent=TRUE)
  if(is.na(n)){
    stop(message=paste("BUG: specified length", len,
                                 "is not an integer."))
  }
  results <- expectThat(length(e$val), equals_legacy(n, label=n), 
                        label=paste0("length(c(", toString(e$val), "))"))                                                   
  if( is(e, "dev") && !results$passed)swirl_out(results$message) 
  return(results$passed)
}

#' Test the result of a computation applied to a specific (user-named) 
#' variable created in a previous question.
#' 
#' Tests the result of a computation such as \code{mean(newVar)} applied
#' to a specific variable created in a previous question and
#' saved behind the scenes as \code{e$newVar}.
#' @param correct_expression expression expected to be applied
#' @return \code{TRUE} or \code{FALSE}
#' @examples
#' \dontrun{
#' # Test if user has taken the mean of a variable created
#' # in an earlier question.
#' #
#' func_of_newvar_equals('mean(newVar)')
#' }
#' @family AnswerTests
func_of_newvar_equals <- function(correct_expression){
  e <- get("e", parent.frame())
  e1 <- cleanEnv(e$snapshot)
  assign(e$newVarName, e$newVar, e1)
  correctExpr <- gsub("newVar", e$newVarName, correct_expression)
  ans <- eval(parse(text=correctExpr), e1)
  results <- expectThat(e$val, 
                        equals_legacy(ans, 
                               label=correctExpr), 
                        label=deparse(e$expr))
  if(is(e, "dev") && !results$passed)swirl_out(results$message)
  return(results$passed)
}

# --- SOURCE FILE: progress.R ---

saveProgress <- function(e)UseMethod("saveProgress")

saveProgress.default <- function(e){
  # save progress
  suppressMessages(suppressWarnings(saveRDS(e, e$progress)))
}

#' Delete a user's progress
#' 
#' @param user The user name whose progress will be deleted.
#' @param path If specified, the directory where the user_data can be found
#' @export
#' @examples
#' \dontrun{
#' 
#' delete_progress("bill")
#' }
delete_progress <- function(user, path = NULL){
  # Make sure user entered a user name
  if(nchar(user) < 1){
    stop("Please enter a valid username.")
  }

  # Find path to user data
  if(is.null(path)) {
    path <- system.file("user_data", user, package = "swirl")  
  }
  
  # Delete all files within a user folder
  if(file.exists(path)){
    invisible(file.remove(list.files(path, full.names = TRUE), recursive = TRUE))
    message(paste0(s()%N%"Deleted progress for user: ", user))
  } else {
    message(paste0(s()%N%"Could not find account for user: ", user))
  }
}

# --- SOURCE FILE: menu.R ---

## Method declarations

mainMenu <- function(e, ...)UseMethod("mainMenu")
welcome <- function(e, ...)UseMethod("welcome")
housekeeping <- function(e, ...)UseMethod("housekeeping")
inProgressMenu <- function(e, choices, ...)UseMethod("inProgressMenu")
courseMenu <- function(e, courses)UseMethod("courseMenu")
courseDir <- function(e)UseMethod("courseDir")
progressDir <- function(e)UseMethod("progressDir")
lessonMenu <- function(e, choices)UseMethod("lessonMenu")
restoreUserProgress <- function(e, selection)UseMethod("restoreUserProgress")
loadLesson <- function(e, ...)UseMethod("loadLesson")
loadInstructions <- function(e, ...)UseMethod("loadInstructions")

# Default course and lesson navigation logic
# 
# This method implements default course and lesson navigation logic, 
# decoupling menu presentation from internal processing of user
# selections. It relies on several methods for menu presentation,
# namely welcome(e), housekeeping(e), inProgressMenu(e, lessons),
# courseMenu(e, courses), and lessonMenu(e, lessons). Defaults 
# are provided.
# 
# @param e persistent environment accessible to the callback
#'@importFrom yaml yaml.load_file
mainMenu.default <- function(e){
  # Welcome the user if necessary and set up progress tracking
  if(!exists("usr",e,inherits = FALSE)){
    e$usr <- welcome(e)
    udat <- file.path(progressDir(e), e$usr)
    if(!file.exists(udat)){
      housekeeping(e)
      dir.create(udat, recursive=TRUE)
    }
    e$udat <- udat
  }
  # If there is no active lesson, obtain one.
  if(!exists("les",e,inherits = FALSE)){
    # First, allow user to continue unfinished lessons
    # if there are any
    pfiles <- inProgress(e)
    response <- ""
    if(length(pfiles) > 0){
      response <- inProgressMenu(e, pfiles)
    }
    if(response != "" ){
      # If the user has chosen to continue, restore progress
      response <- gsub(" ", "_", response)
      response <- paste0(response,".rda")
      restoreUserProgress(e, response)
    } else {
      # Else load a new lesson.
      # Let user choose the course.
      coursesU <- dir(courseDir(e))
      # Eliminate empty directories
      idx <- unlist(sapply(coursesU, 
                    function(x)length(dir(file.path(courseDir(e),x)))>0))
      coursesU <- coursesU[idx]
      
      # If no courses are available, offer to install one
      if(length(coursesU)==0){
        suggestions <- yaml.load_file(file.path(find.package("swirl"), "Courses", "suggested_courses.yaml"))
        choices <- sapply(suggestions, function(x)paste0(x$Course, ": ", x$Description))
        swirl_out(s()%N%"To begin, you must install a course. I can install a course for you from the internet, or I can send you to a web page (https://github.com/swirldev/swirl_courses) which will provide course options and directions for installing courses yourself. (If you are not connected to the internet, type 0 to exit.)")
        choices <- c(choices, s()%N%"Don't install anything for me. I'll do it myself.")
        choice <- select.list(choices, graphics=FALSE)
        n <- which(choice == choices)
        if(length(n) == 0)return(FALSE)
        if(n < length(choices)){
          repeat {
            temp <- try(eval(parse(text=suggestions[[n]]$Install)), silent=TRUE)
            if(is(temp, "try-error")){
              swirl_out(s()%N%"Sorry, but I'm unable to fetch ", sQuote(choice),
                        s()%N%"right now. Are you sure you have an internet connection?",
                        s()%N%"If so, would you like to try again or visit",
                        s()%N%"the course repository for instructions on how to",
                        s()%N%"install a course manually? Type 0 to exit.")
              ch <- c(s()%N%"Try again!", 
                      s()%N%"Send me to the course repository for manual installation.")
              resp <- select.list(ch, graphics=FALSE)
              if(resp == "") return(FALSE)
              if(resp == ch[2]) {
                swirl_out(s()%N%"OK. I'm opening the swirl course respository in your browser.")
                browseURL("https://github.com/swirldev/swirl_courses")
                return(FALSE)
              }
            } else {
              break # Break repeat loop if install is successful
            }
          }
          coursesU <- dir(courseDir(e))
          if(length(coursesU) > 0){
            for(i in 1:length(coursesU)){
              coursesU[i] <- enc2utf8(coursesU[i])
            }
          }
          if(any(is.na(coursesU))){
            coursesU <- dir(courseDir(e))
          }
          # Eliminate empty directories
          idx <- unlist(sapply(coursesU, 
                               function(x)length(dir(file.path(courseDir(e),x)))>0))
          coursesU <- coursesU[idx]
        } else {
          swirl_out(s()%N%"OK. I'm opening the swirl course respository in your browser.")
          browseURL("https://github.com/swirldev/swirl_courses")
          return(FALSE)
        }
      }
      # path cosmetics
      coursesR <- gsub("_", " ", coursesU)
      lesson <- ""
      while(lesson == ""){
        course <- courseMenu(e, coursesR)
        if(!is.null(names(course)) && names(course)=="repo") {
          swirl_out(s()%N%"OK. I'm opening the swirl courses web page in your browser.")
          browseURL("https://github.com/swirldev/swirl_courses")
          return(FALSE)
        }
        if(course=="")return(FALSE)
        # Set temp course name since csv files don't carry attributes
        e$temp_course_name <- course
        # reverse path cosmetics
        courseU <- coursesU[course == coursesR]
        course_dir <- file.path(courseDir(e), courseU)
        
        # Get all files/folders from course dir, excluding MANIFEST
        lessons <- dir(course_dir)
        lessons <- lessons[lessons != "MANIFEST"]
        # If MANIFEST exists in course directory, then order courses
        man_path <- file.path(course_dir, "MANIFEST")
        if(file.exists(man_path)) {
          manifest <- get_manifest(course_dir)
          lessons <- order_lessons(current_order=lessons, 
                                   manifest_order=manifest)
        }
        # If the manifest introduced NAs, try reading without UTF-8
        if(any(is.na(lessons))){
          manifest <- get_manifest(course_dir, utf8 = FALSE)
          lessons <- order_lessons(current_order=lessons,
                                   manifest_order=manifest)
        }
        # If there are still NAs, throw the manifest out
        if(any(is.na(lessons))){
          lessons <- list.dirs(course_dir, full.names = FALSE, recursive = FALSE)
          # Get rid of hidden folders if they exist
          if(length(grep("^\\.", lessons)) > 0){
            lessons <- lessons[-grep("^\\.", lessons)]
          }
        }
        
        # Clean up lesson names
        lessons_clean <- gsub("_", " ", lessons)
        # Let user choose the lesson.
        lesson_choice <- lessonMenu(e, lessons_clean)
        # Set temp lesson name since csv files don't have lesson name attribute
        e$temp_lesson_name <- lesson_choice
        # reverse path cosmetics
        lesson <- ifelse(lesson_choice=="", "",
                         lessons[lesson_choice == lessons_clean])
        # Return to the course menu if the lesson failed to load
        if(lesson == ""){
          if(exists("les", e, inherits=FALSE)){
            rm("les", envir=e, inherits=FALSE)
          }
          lesson <- ""
          next()
        } else {
          # Load the lesson and intialize everything
          e$les <- loadLesson(e, courseU, lesson)
        }
      }
      # For sourcing files which construct figures etc
      e$path <- file.path(courseDir(e), courseU, lesson)
      # If running in 'test' mode and starting partway through 
      # lesson, then complete first part
      if((is(e, "test") || is(e, "datacamp")) && e$test_from > 1) {
        complete_part(e)
      }
      
      # Remove temp lesson name and course name vars, which were surrogates
      # for csv attributes -- they've been attached via lesson() by now
      rm("temp_lesson_name", "temp_course_name", envir=e, inherits=FALSE)
      
      # Initialize the progress bar
      if(!is(e,"datacamp")) {
        e$pbar <- txtProgressBar(style=3)
      }
      e$pbar_seq <- seq(0, 1, length.out=nrow(e$les))
      
      # expr, val, ok, and vis should have been set by the callback.
      # The lesson's current row - could start after 1 if in 'test' mode
      if(is(e, 'test') || is(e, 'datacamp')) {
        e$row <- e$test_from
      } else {
        e$row <- 1
      }
      # The current row's instruction pointer
      e$iptr <- 1
      # A flag indicating we should return to the prompt
      e$prompt <- FALSE
      # The job of loading instructions for this "virtual machine"
      # is relegated to an S3 method to allow for different "programs."
      loadInstructions(e)
      # An identifier for the active row
      e$current.row <- NULL
      # Set up paths and files to save user progress
      # Make file path from lesson info
      fname <- progressName(attr(e$les,"course_name"), attr(e$les,"lesson_name"))
      # path to file 
      e$progress <- file.path(e$udat, fname)
      # indicator that swirl is not reacting to console input
      e$playing <- FALSE
      
      # Create log
      if(isTRUE(getOption("swirl_logging"))){
        e$log <- list(user = e$usr, 
                      course_name = attr(e$les,"course_name"),
                      lesson_name = attr(e$les,"lesson_name"),
                      question_number = NULL,
                      correct = NULL,
                      attempt = NULL,
                      skipped = NULL,
                      datetime = NULL)
      }

      # create the file
      suppressMessages(suppressWarnings(saveRDS(e, e$progress)))
      # post initialization message
      post_init(e)
    }
  }
  return(TRUE)
}

welcome.test <- function(e, ...){
  "author"
}

# Default version.
#' @importFrom stringr str_detect str_trim
welcome.default <- function(e, ...){
  swirl_out(s()%N%"Welcome to swirl! Please sign in. If you've been here before, use the same name as you did then. If you are new, call yourself something unique.", skip_after=TRUE)
  resp <- readline(s()%N%"What shall I call you? ")
  while(str_detect(resp, '[[:punct:]]') || nchar(str_trim(resp)) < 1) {
    swirl_out(s()%N%"Please don't use any quotes or other punctuation in your name.",
              skip_after = TRUE)
    resp <- readline(s()%N%"What shall I call you? ")
  }
  return(resp)
}

# Presents preliminary information to a new user
# 
# @param e persistent environment used here only for its class attribute
# 
housekeeping.default <- function(e){
  swirl_out(paste0(s()%N%"Thanks, ", e$usr, s()%N%". Let's cover a couple of quick housekeeping items before we begin our first lesson. First of all, you should know that when you see '...', that means you should press Enter when you are done reading and ready to continue."))
  readline(s()%N%"\n...  <-- That's your cue to press Enter to continue")
  swirl_out(s()%N%"Also, when you see 'ANSWER:', the R prompt (>), or when you are asked to select from a list, that means it's your turn to enter a response, then press Enter to continue.")
  select.list(c(s()%N%"Continue.", s()%N%"Proceed.", s()%N%"Let's get going!"),
              title=s()%N%"\nSelect 1, 2, or 3 and press Enter", graphics=FALSE)
  swirl_out(s()%N%"You can exit swirl and return to the R prompt (>) at any time by pressing the Esc key. If you are already at the prompt, type bye() to exit and save your progress. When you exit properly, you'll see a short message letting you know you've done so.")
  info()
  swirl_out(s()%N%"Let's get started!", skip_before=FALSE)
  readline("\n...")
}

housekeeping.test <- function(e){}

# A stub. Eventually this should be a full menu
inProgressMenu.default <- function(e, choices){
  nada <- s()%N%"No. Let me start something new."
  swirl_out(s()%N%"Would you like to continue with one of these lessons?")
  selection <- select.list(c(choices, nada), graphics=FALSE)
  # return a blank if the user rejects all choices
  if(identical(selection, nada))selection <- ""
  return(selection)
}

inProgressMenu.test <- function(e, choices) {
  ""
}

# A stub. Eventually this should be a full menu
courseMenu.default <- function(e, choices){
  repo_option <- s()%N%"Take me to the swirl course repository!"
  choices <- c(choices, repo = repo_option)
  swirl_out(s()%N%"Please choose a course, or type 0 to exit swirl.")
  return(select.list(choices, graphics=FALSE))
}

courseMenu.test <- function(e, choices) {
  e$test_course
}

# A stub. Eventually this should be a full menu
lessonMenu.default <- function(e, choices){
  swirl_out(s()%N%"Please choose a lesson, or type 0 to return to course menu.")
  return(select.list(choices, graphics=FALSE))
}

lessonMenu.test <- function(e, choices) {
  e$test_lesson
}

loadLesson.default <- function(e, courseU, lesson){
  # Load the content file
  lesPath <- file.path(courseDir(e), courseU, lesson)
  shortname <- find_lesson(lesPath)
  dataName <- file.path(lesPath,shortname)
  # Handle dependencies
  if(!loadDependencies(lesPath))return(FALSE)
  # Initialize list of official variables
  e$snapshot <- list()
  # initialize course lesson, assigning lesson-specific variables
  initFile <- file.path(lesPath,"initLesson.R")
  if(file.exists(initFile))local({
    source(initFile, local=TRUE)
    # NOTE: the order of the next two statements is important,
    # since a reference to e$snapshot will cause e to appear in
    # local environment.
    xfer(environment(), globalenv())
    # Only add to the "official record" if are auto-detecting new variables
    if(isTRUE(customTests$AUTO_DETECT_NEWVAR)) {
      e$snapshot <- as.list(environment())
    }
  })
  # load any custom tests, returning FALSE if they fail to load
  clearCustomTests()
  loadCustomTests(lesPath)
  
  # Attached class to content based on file extension
  class(dataName) <- get_content_class(dataName)
  
  # Parse content, returning object of class "lesson"
  return(parse_content(dataName, e))
}

restoreUserProgress.default <- function(e, selection){
  # read the progress file
  temp <- readRDS(file.path(e$udat, selection))
  # transfer its contents to e
  xfer(temp, e)
  # Since loadDepencies will have worked once, we don't
  # check for failure here. Perhaps we should.
  loadDependencies(e$path)
  # source the initLesson.R file if it exists
  initf <- file.path(e$path, "initLesson.R")
  if(file.exists(initf))local({
    source(initf, local=TRUE)
    xfer(environment(), globalenv())
  })
  # transfer swirl's "official" list of variables to the
  # global environment.
  if(length(e$snapshot)>0){
    xfer(as.environment(e$snapshot), globalenv())
  }
  # load any custom tests
  clearCustomTests()
  loadCustomTests(e$path)
  # Restore figures which precede current row (Issue #44)
  idx <- 1:(e$row - 1)
  figs <- e$les[idx,"Figure"]
  # Check for missing Figure column (Issue #47) and omit NA's 
  if(is.null(figs) || length(figs) == 0)return()
  figs <- figs[!is.na(figs)]
  figs <- file.path(e$path, figs)
  lapply(figs, function(x)source(file=x, local=TRUE))
}

loadInstructions.default <- function(e){
  e$instr <- list(present, waitUser, testResponse)
}


# UTILITIES

progressName <- function(courseName, lesName){
  pn <- paste0(courseName, "_", lesName, ".rda")
  gsub(" ", "_", pn)
}

inProgress <- function(e){
  pfiles <- dir(e$udat)[grep("[.]rda$", dir(e$udat))]
  pfiles <- gsub("[.]rda", "", pfiles)
  pfiles <- str_trim(gsub("_", " ", pfiles))
  return(pfiles)
}

completed <- function(e){
  pfiles <- dir(e$udat)[grep("[.]done$", dir(e$udat))]
  pfiles <- gsub("[.]done", "", pfiles)
  pfiles <- gsub("[.]rda", "", pfiles)
  pfiles <- str_trim(gsub("_", " ", pfiles))
  return(pfiles)
}

get_manifest <- function(course_dir, utf8 = TRUE) {
  if(utf8){
    man <- readLines(file.path(course_dir, "MANIFEST"), warn=FALSE, encoding = "UTF-8")
  } else {
    man <- readLines(file.path(course_dir, "MANIFEST"), warn=FALSE)
  }
  # Remove leading and trailing whitespace
  man <- str_trim(man)
  # Remove empty lines
  man <- man[which(man != "")]
}

# Take vector of lessons and return in order given by manifest.
# Any courses not included in manifest are excluded!
order_lessons <- function(current_order, manifest_order) {
  current_order[match(manifest_order, current_order)]
}

courseDir.default <- function(e){
  # e's only role is to determine the method used
  swirl_courses_dir()
}

progressDir.default <- function(e) {
  swirl_data_dir()
}

# Default for determining the user
getUser <- function()UseMethod("getUser")
getUser.default <- function(){"swirladmin"}

# --- SOURCE FILE: swirl.R ---

#' An interactive learning environment for R and statistics.
#' 
#' This function presents a choice of course lessons and interactively
#' tutors a user through them. A user may be asked to watch a video, to
#' answer a multiple-choice or fill-in-the-blanks question, or to
#' enter a command in the R console precisely as if he or she were 
#' using R in practice. Emphasis is on the last, interacting with the
#' R console. User responses are tested for correctness and hints are
#' given if appropriate. Progress is automatically saved so that a user
#' may quit at any time and later resume without losing work.
#' 
#' There are several ways to exit swirl: by typing \code{bye()} while in the R
#' console, by hitting the Esc key while not in the R console, or by
#' entering 0 from the swirl course menu. swirl will print a goodbye 
#' message whenever it exits. 
#' 
#' While swirl is in operation, it may be controlled by entering special
#' commands in the R console. One of the special commands is \code{bye()} 
#' as discussed above. Others are \code{play()}, \code{nxt()}, \code{skip()},
#' and \code{info()}. The parentheses are important.
#' 
#' Sometimes a user will want to play around in the R console without
#' interference or commentary from swirl. This can be accomplished by
#' using the special command \code{play()}. swirl will remain in operation,
#' silently, until the special command \code{nxt()} is entered.
#' 
#' The special command \code{skip()} can be used to skip a question if 
#' necessary. swirl will enter the correct answer and notify the
#' user of the names of any new variables which it may have created
#' in doing so. These may be needed for subsequent questions.
#' 
#' Finally, \code{info()} may be used to display a list of the special commands
#' themselves with brief explanations of what they do.
#' @param resume.class for development only; please accept the default.
#' @param ... arguments for special purposes only, such as lesson testing
#' @export
#' @importFrom stringr str_c str_trim str_split str_length 
#' @importFrom stringr str_detect str_locate fixed str_split_fixed
#' @importFrom methods is
#' @examples
#' \dontrun{
#' 
#' swirl()
#' }
swirl <- function(resume.class="default", ...){
  # Creates an environment, e, defines a function, cb, and registers
  # cb as a callback with data argument, e. The callback retains a
  # reference to the environment in which it was created, environment(cb),
  # hence that environment, which also contains e, persists as long
  # as cb remains registered. Thus e can be used to store infomation
  # between invocations of cb.
  removeTaskCallback("mini")
  # e lives here, in the environment created when swirl() is run
  e <- new.env(globalenv())
  # This dummy object of class resume.class "tricks" the S3 system
  # into calling the proper resume method. We retain the "environment"
  # class so that as.list(e) works.
  class(e) <- c("environment", resume.class)
  # The callback also lives in the environment created when swirl()
  # is run and retains a reference to it. Because of this reference,
  # the environment which contains both e and cb() persists as
  # long as cb() remains registered.
  cb <- function(expr, val, ok, vis, data=e){
    # The following will modify the persistent e
    e$expr <- expr
    e$val <- val
    e$ok <- ok
    e$vis <- vis
    # The result of resume() will determine whether the callback
    # remains active
    return(resume(e, ...))
  }
  addTaskCallback(cb, name="mini")
  invisible()
}

## SPECIAL COMMANDS

#' Exit swirl.
#' 
#' swirl operates by installing a callback function which responds
#' to commands entered in the R console. This is how it captures
#' and tests answers given by the user in the R console. swirl will
#' remain in operation until this callback is removed, which is
#' what \code{bye()} does.
#' @export
#' @examples
#' \dontrun{
#' 
#' | Create a new variable called `x` that contains the number 3.
#' 
#' > bye()
#' 
#' | Leaving swirl now. Type swirl() to resume.
#' }
bye <- function(){
  removeTaskCallback("mini")
  swirl_out(s()%N%"Leaving swirl now. Type swirl() to resume.", skip_after=TRUE)
  invisible()
}

#' Begin the upcoming question or unit of instruction.
#' 
#' This is the way to regain swirl's attention after viewing
#' a video or \code{play()}'ing around in the console. 
#' @export
#' @examples
#' \dontrun{
#' 
#' | Create a new variable called `y` that contains the number 8.
#' 
#' > play()
#' 
#' | Entering play mode. Experiment as you please, then type nxt()
#' | when you ready to resume the lesson.
#' 
#' > 10/14
#' > [1] 0.7142857
#' > zz <- 99
#' > zz
#' > [1] 99
#' > nxt()
#' 
#' | Resuming lesson...
#' }
nxt <- function(){invisible()}

#' Skip the current unit of instruction.
#' 
#' swirl will enter the correct answer and notify the
#' user of the names of any new variables which it may have created
#' in doing so. These may be needed for subsequent questions.
#' @export
#' @examples
#' \dontrun{
#' 
#' | Create a new variable called `y` that contains the number 8.
#' 
#' > skip()
#' 
#' | I've entered the correct answer for you.
#' 
#' | In doing so, I've created the variable(s) y, which you may need later.
#' }
skip <- function(){invisible()}

#' Start over on the current script question.
#' 
#' During a script question, this will reset the script
#' back to its original state, which can be helpful if you
#' get stuck.
#' @export
reset <- function(){invisible()}

#' Submit the active R script in response to a question.
#' 
#' When a swirl question requires the user to edit an R script, the
#' \code{submit()} function allows the user to submit their response.
#' @export
#' @examples
#' \dontrun{
#' 
#' | Create a function called f that takes one argument, x, and
#' | returns the value of x squared.
#' 
#' > submit()
#' 
#' | You are quite good my friend!
#' }
submit <- function(){invisible()}

#' Tell swirl to ignore console input for a while.
#' 
#' It is sometimes useful to play around in the R console out of
#' curiosity or to solidify a concept. This command will cause
#' swirl to remain idle, allowing the user to experiment at will,
#' until the command \code{nxt()} is entered. 
#' @export
#' @examples
#' \dontrun{
#' 
#' | Create a new variable called `y` that contains the number 8.
#' 
#' > play()
#' 
#' | Entering play mode. Experiment as you please, then type nxt()
#' | when you ready to resume the lesson.
#' 
#' > 10/14
#' > [1] 0.7142857
#' > zz <- 99
#' > zz
#' > [1] 99
#' > nxt()
#' 
#' | Resuming lesson...
#' }
play <- function(){invisible()}

#' Return to swirl's main menu.
#' 
#' Return to swirl's main menu from a lesson in progress.
#' @export
#' @examples
#' \dontrun{
#' 
#' | The simplest way to create a sequence of numbers in R is by using
#' | the `:` operator. Type 1:20 to see how it works.
#' 
#' > main()
#' 
#' | Returning to the main menu...
#' }
main <- function(){invisible()}

#' Restart the current swirl lesson.
#'
#' Restart the current swirl lesson.
#'
#' @export
restart <- function(){invisible()}

#' Display a list of special commands.
#' 
#' Display a list of the special commands, \code{bye()}, \code{play()}, 
#' \code{nxt()}, \code{skip()}, and \code{info()}.
#' @export
info <- function(){
  swirl_out(s()%N%"When you are at the R prompt (>):")
  swirl_out(s()%N%"-- Typing skip() allows you to skip the current question.", skip_before=FALSE)
  swirl_out(s()%N%"-- Typing play() lets you experiment with R on your own; swirl will ignore what you do...", skip_before=FALSE)
  swirl_out(s()%N%"-- UNTIL you type nxt() which will regain swirl's attention.", skip_before=FALSE)
  swirl_out(s()%N%"-- Typing bye() causes swirl to exit. Your progress will be saved.", skip_before=FALSE)
  swirl_out(s()%N%"-- Typing main() returns you to swirl's main menu.", skip_before=FALSE)
  swirl_out(s()%N%"-- Typing info() displays these options again.", skip_before=FALSE, skip_after=TRUE)
  invisible()
}

## RESUME METHOD

resume <- function(...)UseMethod("resume")

# Default method resume implements a finite state (or virtual) machine. 
# It runs a fixed "program" consisting of three "instructions" which in 
# turn present information, capture a user's response, and test and retry 
# if necessary. The three instructions are themselves S3 methods which 
# depend on the class of the active row of the course lesson. The 
# instruction set is thus extensible. It can be found in R/instructionSet.R. 

resume.default <- function(e, ...){
  # Specify additional arguments
  args_specification(e, ...)
  
  esc_flag <- TRUE
  on.exit(if(esc_flag)swirl_out(s()%N%"Leaving swirl now. Type swirl() to resume.", skip_after=TRUE))
  # Trap special functions
  if(uses_func("info")(e$expr)[[1]]){
    esc_flag <- FALSE
    return(TRUE)
  }
  
  if(uses_func("nxt")(e$expr)[[1]]){
    do_nxt(e)
  }
  
  # The user wants to reset their script to the original
  if(uses_func("reset")(e$expr)[[1]]) {
    do_reset(e)
  }
  
  # The user wants to submit their R script
  if(uses_func("submit")(e$expr)[[1]]){
    do_submit(e)
  }
  
  if(uses_func("play")(e$expr)[[1]]){
    do_play(e)
  }
  
  # If the user wants to skip the current question, do the bookkeeping.
  if(uses_func("skip")(e$expr)[[1]]){
    # Increment a skip count kept in e.
    if(!exists("skips", e)) e$skips <- 0
    e$skips <- 1 + e$skips
    e$skipped <- TRUE
    # Enter the correct answer for the user
    # by simulating what the user should have done
    correctAns <- e$current.row[,"CorrectAnswer"]
    
    # If we are on a script question, the correct answer should
    # simply source the correct script
    if(is(e$current.row, "script") && is.na(correctAns)) {
      correct_script_path <- e$correct_script_temp_path
      if(file.exists(correct_script_path)) {
        # Get contents of the correct script
        e$script_contents <- readLines(correct_script_path, warn = FALSE)
        # Save expr to e
        e$expr <- try(parse(text = e$script_contents), silent = TRUE)
        # Source the correct script
        try(source(correct_script_path))
        # Inform the user and open the correct script
        swirl_out(s()%N%"I just sourced the following script, which demonstrates one possible solution.",
                  skip_after=TRUE)
        file.edit(correct_script_path)
        readline(s()%N%"Press Enter when you are ready to continue...")
      }
      
    # If this is not a script question...
    } else {
      # In case correctAns refers to newVar, add it
      # to the official list AND the global environment
      if(exists("newVarName",e)) {
        correctAns <- gsub("newVar", e$newVarName, correctAns)
      }
      e$expr <- parse(text=correctAns)[[1]]
      ce <- cleanEnv(e$snapshot)
      # evaluate e$expr keeping value and visibility information
      # store the result in temporary object evaluation in order
      # to avoid double potentially time consuming eval call
      evaluation <- withVisible(eval(e$expr, ce))
      e$vis <- evaluation$visible
      e$val <- suppressMessages(suppressWarnings(evaluation$value))
      xfer(ce, globalenv())
      ce <- as.list(ce)
      
      # Inform the user and expose the correct answer
      swirl_out(s()%N%"Entering the following correct answer for you...",
                skip_after=TRUE)
      message("> ", e$current.row[, "CorrectAnswer"])

      if(e$vis & !is.null(e$val)) {
        print(e$val)
      }
    }
    
    # Make sure playing flag is off since user skipped
    e$playing <- FALSE
    
  # If the user is not trying to skip and is playing, 
  # ignore console input, but remain in operation.
  } else if(exists("playing", envir=e, inherits=FALSE) && e$playing) {
    esc_flag <- FALSE
    return(TRUE)
  }    
  
  # If the user want to return to the main menu, do the bookkeeping
  if(uses_func("main")(e$expr)[[1]]){
    do_main(e)
  }

  # If the user want to restart the lesson, do the bookkeeping
  if(uses_func("restart")(e$expr)[[1]]){
    do_restart(e)
  }
  
  # If user is looking up a help file, ignore their input
  # unless the correct answer involves do so
  if(uses_func("help")(e$expr)[[1]] || 
       uses_func("`?`")(e$expr)[[1]]){
    # Get current correct answer
    corrans <- e$current.row[, "CorrectAnswer"]
    # Parse the correct answer
    corrans_parsed <- parse(text = corrans)
    # See if it contains ? or help
    uses_help <- uses_func("help")(corrans_parsed)[[1]] ||
      uses_func("`?`")(corrans_parsed)[[1]]
    if(!uses_help) {
      esc_flag <- FALSE
      return(TRUE)
    }
  }
  
  # Method menu initializes or reinitializes e if necessary.
  temp <- mainMenu(e)
  # If menu returns FALSE, the user wants to exit.
  if(is.logical(temp) && !isTRUE(temp)){
    swirl_out(s()%N%"Leaving swirl now. Type swirl() to resume.", skip_after=TRUE)
    esc_flag <- FALSE # To supress double notification
    return(FALSE)
  }
  
  # if e$expr is NOT swirl() or nxt(), the user has just responded to
  # a question at the command line. Simulate evaluation of the
  # user's expression and save any variables changed or created
  # in e$delta. 
  # TODO: Eventually make auto-detection of new variables an option.
  # Currently it can be set in customTests.R
  if(!uses_func("swirl")(e$expr)[[1]] &&
       !uses_func("swirlify")(e$expr)[[1]] &&
       !uses_func("testit")(e$expr)[[1]] &&
       !uses_func("demo_lesson")(e$expr)[[1]] &&
       !uses_func("nxt")(e$expr)[[1]] &&
       isTRUE(customTests$AUTO_DETECT_NEWVAR)) {
    e$delta <- mergeLists(safeEval(e$expr, e), e$delta)
  }
  # Execute instructions until a return to the prompt is necessary
  while(!e$prompt){
    # If the lesson is complete, save progress, remove the current
    # lesson from e, and invoke the top level menu method.
    # Below, min() ignores e$test_to if it is NULL (i.e. not in 'test' mode)
    if(e$row > min(nrow(e$les), e$test_to)) {
      # If in test or datacamp mode, we don't want to run another lesson
      if(is(e, "test") || is(e, "datacamp")) {
        post_finished(e)
        esc_flag <- FALSE # to supress double notification
        return(FALSE)
      }
      saveProgress(e)
      # form a new path for the progress file
      # which indicates completion and doesn't
      # fit the regex pattern "[.]rda$" i.e.
      # doesn't end in .rda, hence won't be
      # recognized as an active progress file.
      new_path <- paste(e$progress,".done", sep="")
      # rename the progress file to indicate completion
      if(file.exists(new_path))file.remove(new_path)
      file.rename(e$progress, new_path)
      # Coursera check
      courseraCheck(e)
      # remove the current lesson and any custom tests
      if(exists("les", e, inherits=FALSE)){
        rm("les", envir=e, inherits=FALSE)
      }
      # Reset skip count if it exists
      if(exists("skips", e)) e$skips <- 0
      clearCustomTests()
      
      # Save log
      if(isTRUE(getOption("swirl_logging"))){
        saveLog(e)
      }
      
      # Let user know lesson is complete
      swirl_out(s()%N%"You've reached the end of this lesson! Returning to the main menu...")
      # let the user select another course lesson
      temp <- mainMenu(e)
      # if menu returns FALSE, user wants to quit.
      if(is.logical(temp) && !isTRUE(temp)){
        swirl_out(s()%N%"Leaving swirl now. Type swirl() to resume.", skip_after=TRUE)
        esc_flag <- FALSE # to supress double notification
        return(FALSE)
      }
    }
    # If we are ready for a new row, prepare it
    if(e$iptr == 1){      
      # Display progress
      post_progress(e)
      
      #  Any variables changed or created during the previous
      #  question must have been correct or we would not be about
      #  to advance to a new row. Incorporate these in the list
      #  of swirl's "official" names and values.
      if (!is.null(e$delta)){
        e$snapshot <- mergeLists(e$delta,e$snapshot)
      }
      e$delta <- list()
      saveProgress(e)
      e$current.row <- e$les[e$row,]
      # Prepend the row's swirl class to its class attribute
      class(e$current.row) <- c(e$current.row[,"Class"], 
                                       class(e$current.row))
    }
    
    # Execute the current instruction
    e$instr[[e$iptr]](e$current.row, e)
    # Check if a side effect, such as a sourced file, has changed the
    # values of any variables in the official list. If so, add them
    # to the list of changed variables.
    for(nm in names(e$snapshot)){
      if(exists(nm, globalenv()) &&
           !identical(e$snapshot[[nm]], get(nm, globalenv()))){
        e$delta[[nm]] <- get(nm, globalenv())
      }
    }
  }
  
  e$prompt <- FALSE
  esc_flag <- FALSE
  return(TRUE)
}

# --- SOURCE FILE: actions.R ---

do_nxt <- function(e)UseMethod("do_nxt")
do_reset <- function(e)UseMethod("do_rst")
do_submit <- function(e)UseMethod("do_submit")
do_play <- function(e)UseMethod("do_play")
do_main <- function(e)UseMethod("do_main")
do_restart <- function(e)UseMethod("do_restart")

do_nxt.default <- function(e) {
  ## Using the stored list of "official" swirl variables and values,
  #  assign variables of the same names in the global environment
  #  their "official" values, in case the user has changed them
  #  while playing.
  if(length(e$snapshot)>0)xfer(as.environment(e$snapshot), globalenv())
  swirl_out(s()%N%"Resuming lesson...")
  e$playing <- FALSE
  e$iptr <- 1  
}

do_reset.default <- function(e) {
  e$playing <- FALSE
  e$reset <- TRUE
  e$iptr <- 2
  swirl_out(s()%N%"I just reset the script to its original state. If it doesn't refresh immediately, you may need to click on it.", 
            skip_after = TRUE)
}

do_submit.default <- function(e) {
  e$playing <- FALSE
  # Get contents from user's submitted script
  e$script_contents <- readLines(e$script_temp_path, warn = FALSE)
  # Save expr to e
  e$expr <- try(parse(text = e$script_contents), silent = TRUE)
  swirl_out(s()%N%"Sourcing your script...", skip_after = TRUE)
  try(source(e$script_temp_path, encoding = "UTF-8"))
}

do_play.default <- function(e) {
  swirl_out(s()%N%"Entering play mode. Experiment as you please, then type nxt() when you are ready to resume the lesson.", skip_after=TRUE)
  e$playing <- TRUE
}

do_main.default <- function(e) {
  swirl_out(s()%N%"Returning to the main menu...")
  # Remove the current lesson. Progress has been saved already.
  if(exists("les", e, inherits=FALSE)){
    rm("les", envir=e, inherits=FALSE)
  }
}

do_restart.default <- function(e) {
  swirl_out(s()%N%"This feature is not implemented yet for Swirl.")
}

# --- SOURCE FILE: args_specification.R ---

args_specification <- function(e, ...)UseMethod("args_specification")

args_specification.default <- function(e, ...) {
  # in normal, interactive mode, do nothing
}

args_specification.test <- function(e, ...) {
  # Capture ... args
  targs <- list(...)
  # Check if appropriately named args exist
  if(is.null(targs$test_course) || is.null(targs$test_lesson)) {
    stop(s()%N%"Must specify 'test_course' and 'test_lesson' to run in 'test' mode!")
  } else {
    # Make available for use in menu functions
    e$test_lesson <- targs$test_lesson
    e$test_course <- targs$test_course
  }
  # Check that 'from' is less than 'to' if they are both provided
  if(!is.null(targs$from) && !is.null(targs$to)) {
    if(targs$from >= targs$to) {
      stop(s()%N%"Argument 'to' must be strictly greater than argument 'from'!")
    }
  }
  if(is.null(targs$from)) {
    e$test_from <- 1
  } else {
    e$test_from <- targs$from
  }
  if(is.null(targs$to)) {
    e$test_to <- 999 # Lesson will end naturally before this
  } else {
    e$test_to <- targs$to
  }
} 

# --- SOURCE FILE: email_info.R ---

#' Send diagnostic email to swirl admin
#' 
#' Typing \code{email_admin()} at the prompt will attempt to open
#' a new email in your default browser or email client. The email
#' will include space for you to describe the problem you are
#' experiencing. It will also have the output from \code{sessionInfo},
#' which you should not alter.
#' 
#' @export
email_admin <- function() {
  # Get session info and swirl package version
  si <- capture.output(sessionInfo())
  pv <- packageVersion('swirl')
  
  # Set up email elements address, subject, and body
  address <- 'info@swirlstats.com'
  subject <- paste('Need help: swirl', pv)
  body <- paste('Brief description of problem: \n\n',
                paste(rep('#', 15),  collapse = ''),
                paste(si, collapse = '\n'),
                sep = '\n\n')

  # Send email
  email(address, subject, body)

  invisible()
}

# email() and email_browser() were copied directly from Hadley 
# Wickham's devtools package.

# http://tools.ietf.org/html/rfc2368
email <- function(address, subject, body) {
  url <- paste(
    "mailto:",
    URLencode(address),
    "?subject=", URLencode(subject),
    "&body=", URLencode(body),
    sep = ""
  )
  
  tryCatch({
    browseURL(url, browser = email_browser())},
    error = function(e) {
      message("Sending failed with error: ", e$message)
      cat("To: ", address, "\n", sep = "")
      cat("Subject: ", subject, "\n", sep = "")
      cat("\n")
      cat(body, "\n", sep = "")
    }
  )
  
  invisible(TRUE)
}

email_browser <- function() {
  if (!identical(.Platform$GUI, "RStudio"))
    return (getOption("browser"))
  
  # Use default browser, even if RStudio running
  if (.Platform$OS.type == "windows")
    return (NULL)
  
  browser <- Sys.which(c("xdg-open", "open"))
  browser[nchar(browser) > 0][[1]]
}

# --- SOURCE FILE: global.R ---

utils::globalVariables(c("URLencode", "browseURL", "capture.output",
                         "file.edit", "getS3method", "head", "install.packages",
                         "packageVersion", "read.csv", "select.list", "sessionInfo",
                         "setTxtProgressBar", "tail", "txtProgressBar", "unzip",
                         "zip"))

# --- SOURCE FILE: instructionSet.R ---

# Instruction set for swirl.R's "virtual machine".

# All classes first Output, all in the same way, hence one method
# suffices.
#
present <- function(current.row, e)UseMethod("present")

present.default <- function(current.row, e){
  # Present output to user
  post_exercise(e, current.row)
  # Initialize attempts counter, if necessary
  if(!exists("attempts", e)) e$attempts <- 1
  # Increment pointer
  e$iptr <- 1 + e$iptr
}

# All classes then wait for user response, in different ways, hence
# different methods are required. Text and video are both finished
# at this point.

waitUser <- function(current.row, e)UseMethod("waitUser")

waitUser.default <- function(current.row, e){
  readline("...")
  e$row <- 1 + e$row
  e$iptr <- 1
}

waitUser.text_question <- function(current.row, e){
  e$val <- str_trim(unlist(strsplit(readline("ANSWER: "),",")))
  e$iptr <- 1 + e$iptr
}

waitUser.text_many_question <- function(current.row, e){
  e$val <- str_trim(unlist(strsplit(readline("ANSWER: "),",")))
  e$iptr <- 1 + e$iptr
}

waitUser.text_order_question <- function(current.row, e){
  e$val <- str_trim(unlist(strsplit(readline("ANSWER: "),",")))
  e$iptr <- 1 + e$iptr
}


waitUser.video <- function(current.row, e){
  response <- readline("Yes or No? ")
  if(tolower(response) %in% c("y", "yes")){
    swirl_out(s()%N%"Type nxt() to continue")
    e$prompt <- TRUE
    e$playing <- TRUE
    browseURL(current.row[,"VideoLink"])
  }
  e$row <- 1 + e$row
  e$iptr <- 1
}

waitUser.figure <- function(current.row, e){
  fp <- file.path(e$path, current.row[,"Figure"])
  local({
    source(fp,local=TRUE)
    xfer(environment(), globalenv())
    temp <- as.list(environment())
    e$snapshot <- c(e$snapshot, temp)
  })
  readline("...")
  e$row <- 1 + e$row
  e$iptr <- 1
}


waitUser.mult_question <- function(current.row, e){
  # Use strsplit with split=";" to separate the choices
  # Use select.list to get the user's choice.
  choices <- strsplit(current.row[,"AnswerChoices"],";")
  # Strsplit returns a list but we want only its first element,
  # a vector of choices. Use str_trim (pkg stringr) to remove
  # leading and trailing white space from the choices.
  choices <- str_trim(choices[[1]])
  # Store the choice in e$val for testing
  e$val <- post_mult_question(e, choices)
  
  e$iptr <- 1 + e$iptr
}


waitUser.exact_question <- function(current.row, e){
  # Indicate a return to the prompt is necessary.
  e$prompt <- TRUE
  e$iptr <- 1 + e$iptr
}

waitUser.range_question <- function(current.row, e){
  # Indicate a return to the prompt is necessary.
  e$prompt <- TRUE
  e$iptr <- 1 + e$iptr
}

waitUser.cmd_question <- function(current.row, e){
  # Indicate a return to the prompt is necessary.
  e$prompt <- TRUE
  e$iptr <- 1 + e$iptr
}

#' @importFrom tools file_path_sans_ext
waitUser.script <- function(current.row, e){
  # If this is the first attempt or the user wants to start over, 
  # then create temp files so nothing gets overwritten
  if(e$attempts == 1 || isTRUE(e$reset)) {
    # Get original script name
    orig_script_name <- current.row[,"Script"]
    # Get file path of original script
    orig_script_path <- file.path(e$path, "scripts", orig_script_name)
    # Path temp copy of original script
    e$script_temp_path <- file.path(tempdir(), orig_script_name)
    
    # Original correct script name
    correct_script_name <- paste0(
      tools::file_path_sans_ext(orig_script_name), "-correct.R")
    # Original correct script path
    correct_script_path <- file.path(e$path, "scripts", correct_script_name)
    # Path of temp correct script
    e$correct_script_temp_path <- file.path(tempdir(), correct_script_name)
    
    # Copy original script to temp file
    file.copy(orig_script_path, e$script_temp_path, overwrite = TRUE)
    # Copy original correct to temp correct
    file.copy(correct_script_path, e$correct_script_temp_path, overwrite = TRUE)
    
    # Set reset flag back to FALSE
    e$reset <- FALSE
  }
  # Have user edit the copy. This will reopen the file if 
  # accidentally closed
  file.edit(e$script_temp_path)
  # Give instructions
  # swirl_out("INSTRUCTIONS: Edit the script and experiment in the console as much as you want. When you are ready to move on, SAVE YOUR SCRIPT and type submit() at the prompt. The script will remain open until you close it.",
  #          skip_before = FALSE, skip_after = TRUE)
  # Indicate a return to the prompt is necessary
  e$prompt <- TRUE
  # Enter 'play' mode so that user can mess around in the console
  e$playing <- TRUE
  # Advance lesson
  e$iptr <- 1 + e$iptr
}

# Only the question classes enter a testing loop. Testing is the
# same in both cases. If the response is correct they indicate
# instruction should progress. If incorrect, they publish a hint
# and return to the previous step.
testResponse <- function(current.row, e)UseMethod("testResponse")

testResponse.default <- function(current.row, e){
  if(isTRUE(getOption("swirl_logging"))){
    e$log$question_number <- c(e$log$question_number, e$row)
    e$log$attempt <- c(e$log$attempt, e$attempts)
    e$log$skipped <- c(e$log$skipped, e$skipped)
    e$log$datetime <- c(e$log$datetime, as.numeric(Sys.time()))
  } 
  
  # Increment attempts counter
  e$attempts <- 1 + e$attempts
  # Get answer tests
  tests <- current.row[,"AnswerTests"]
  if(is.na(tests) || tests == ""){
    results <- is(e, "dev")
    if(!results){
      stop(s()%N%"BUG: There are no tests for this question!")
    }
  } else {
    tests <- str_trim(unlist(strsplit(tests,";")))
    results <- lapply(tests, function(keyphrase){testMe(keyphrase,e)})
  }
  correct <- !(FALSE %in% unlist(results))
  if(correct){
    if(isTRUE(getOption("swirl_logging"))){
      e$log$correct <- c(e$log$correct, TRUE)
    }  
    
    mes <- praise()
    post_result(e, passed = correct, feedback = mes, hint = NULL)
    e$iptr <- 1
    e$row <- 1 + e$row
    # Reset attempts counter, since correct
    e$attempts <- 1
  } else {
    if(isTRUE(getOption("swirl_logging"))){
      e$log$correct <- c(e$log$correct, FALSE)
    }
    
    # Restore the previous global environment from the official
    # in case the user has garbled it, e.g., has typed x <- 3*x
    # instead of x <- 2*x by mistake. The hint might say to type
    # x <- 2*x, which would result in 6 times the original value
    # of x unless the original value is restored.
    if(length(e$snapshot)>0)xfer(as.environment(e$snapshot), globalenv())
    mes <- tryAgain()
    if(is(current.row, "cmd_question") && !is(e, "datacamp")) {
      mes <- paste(mes, s()%N%"Or, type info() for more options.")
    }
    hint <- current.row[,"Hint"]
    post_result(e, passed = correct, feedback = mes, hint = if(is.na(hint)) NULL else hint)
    e$iptr <- e$iptr - 1
  }
  # reset skipped info
  e$skipped <- FALSE
}

testMe <- function(keyphrase, e){
  # patch to accommodate old-style tests
  oldcourse <- attr(e$les, "course_name") %in%
    c("Data Analysis", "Mathematical Biostatistics Boot Camp",
      "Open Intro")

  if(oldcourse){
    # Use old test syntax
    # Add a new class attribute to the keyphrase using
    # the substring left of its first "=".
    attr(keyphrase, "class") <- c(class(keyphrase),
                                  strsplit(keyphrase, "=")[[1]][1])
    return(runTest(keyphrase, e))
  } else {
    # Use new test syntax
    return(eval(parse(text=keyphrase)))
  }
}

# CUSTOM TEST SUPPORT. An environment for custom tests is inserted
# "between" function testMe and the swirl namespace. That is,
# an environment, customTests, is created with parent swirl
# and child testMe. Code evaluated within testMe will thus search
# for functions first in customTests, and then in the swirl namespace.
#
# Custom tests must be defined in a file named "customTests.R" in the
# lesson directory. Tests in such files are loaded into environment
# customTests when a lesson is first loaded or progress is restored.
# The environment is cleared between lessons.

# An environment with parent swirl to hold custom tests.
customTests <- new.env(parent=environment(testMe))
# Make customTests the parent of testMe.
environment(testMe) <- customTests

# Function to load custom tests from a source file.
loadCustomTests <- function(lespath){
  customTests$AUTO_DETECT_NEWVAR <- TRUE
  cfile <- file.path(lespath,"customTests.R")
  if(file.exists(cfile)){
    source(cfile, local=customTests)
  }
  return(TRUE) # legacy
}

# Function to remove everything from environment customTests
clearCustomTests <- function(){
  remove(list=ls(customTests), envir=customTests)
}

# --- SOURCE FILE: lesson_constructor.R ---

# Constructor function for objects of class "lesson"
lesson <- function(df, lesson_name=NULL, course_name=NULL, author=NULL, 
                   type=NULL, organization=NULL, version=NULL, partner=NULL) {
  
  if(!is.data.frame(df)) 
    stop("Argument 'df' must be a data frame!")
  
  # Adding secondary class of data.frame allows lessons to retain data.frame attributes (e.g. dim())
  structure(df, lesson_name=lesson_name, course_name=course_name, author=author,
            type=type, organization=organization, version=version, partner=partner,
            class=c("lesson", "data.frame"))
}

# --- SOURCE FILE: log.R ---

saveLog <- function(e)UseMethod("saveLog")

saveLog.default <- function(e){
  # save log
  suppressMessages(suppressWarnings(
    saveRDS(e$log, file.path(e$udat, paste0(as.integer(Sys.time()), ".swlog")))))
}

# --- SOURCE FILE: parse_content.R ---

find_lesson <- function(lesson_dir) {
  # Find 'lesson' file with or without extension
  grep("^lesson[.]?[A-Za-z]*$", list.files(lesson_dir), value=TRUE)
}

#' @importFrom tools file_ext
get_content_class <- function(file_name) {
  ext <- file_ext(file_name)
  tolower(ext)
}

### FUNCTIONS THAT RETURN LESSON OBJECT WITH ASSOCIATED ATTRIBUTES ###

parse_content <- function(file, e) UseMethod("parse_content")

parse_content.default <- function(file, e) {
  # If no extension on lesson file, then assume it's yaml
  parse_content.yaml(file, e)
}

parse_content.csv <- function(file, e) {
  df <- read.csv(file, as.is=TRUE)
  # Return lesson object
  lesson(df, lesson_name=e$temp_lesson_name, course_name=e$temp_course_name)
}

parse_content.rmd <- function(file, e) {
  rmd2df(file)
}

wrap_encoding <- function(raw_yaml) {
  if (class(raw_yaml) == "list") {
    retval <- lapply(raw_yaml, wrap_encoding)
    attributes(retval) <- attributes(raw_yaml)
    retval
  } else {
    if (class(raw_yaml) == "character") {
      if (Encoding(raw_yaml) == "unknown") {
        Encoding(raw_yaml) <- "UTF-8"
      }
    }
    raw_yaml
  }
}

#' @importFrom yaml yaml.load_file
parse_content.yaml <- function(file, e){
  newrow <- function(element){
    temp <- data.frame(Class=NA, Output=NA, CorrectAnswer=NA,
                       AnswerChoices=NA, AnswerTests=NA, 
                       Hint=NA, Figure=NA, FigureType=NA, 
                       VideoLink=NA, Script=NA)
    for(nm in names(element)){
      # Only replace NA with value if value is not NULL, i.e. instructor
      # provided a nonempty value
      if(!is.null(element[[nm]])) {
        temp[,nm] <- element[[nm]]
      }
    }
    temp
  }
  raw_yaml <- yaml.load_file(file)
  raw_yaml <- wrap_encoding(raw_yaml)
  temp <- lapply(raw_yaml[-1], newrow)
  df <- NULL
  for(row in temp){
    df <- rbind(df, row)
  }
  meta <- raw_yaml[[1]]
  lesson(df, lesson_name=meta$Lesson, course_name=meta$Course,
         author=meta$Author, type=meta$Type, organization=meta$Organization,
         version=meta$Version, partner=meta$Partner)
}

# --- SOURCE FILE: post.R ---

post_init <- function(e) UseMethod("post_init")
post_exercise <- function(e, current.row) UseMethod("post_exercise")
post_mult_question <- function(e, choices) UseMethod("post_mult_question")
post_result <- function(e, passed, submission, feedback, hint) UseMethod("post_result")
post_progress <- function(e) UseMethod("post_progress")
post_finished <- function(e) UseMethod("post_finished")

post_init.default <- function(e) {
  # do nothing
}

post_exercise.default <- function(e, current.row) {
  # Suppress extra space if multiple choice
  is_mult <- is(e$current.row, "mult_question")
  # Present output to user
  swirl_out(current.row[, "Output"], skip_after = !is_mult)
}

post_mult_question.default <- function(e, choices) {
  return(select.list(sample(choices), graphics=FALSE))
}

post_result.default <- function(e, passed, feedback, hint) {
  swirl_out(feedback)
  if(!passed) {
    # If hint is specified, print it. Otherwise, just skip a line.
    if(!is.null(hint)) {
      # Suppress extra space if multiple choice
      is_mult <- is(e$current.row, "mult_question")
      swirl_out(hint, skip_after = !is_mult) 
    } else {
      message()
    }
  }
}

post_progress.default <- function(e) {
  cat("\n")
  setTxtProgressBar(e$pbar, e$pbar_seq[e$row])
}

post_finished.default <- function(e) {
  swirl_out(s()%N%"Lesson complete! Exiting swirl now...", skip_after=TRUE)
}

# --- SOURCE FILE: rmatch_calls.R ---

# Reference: Creating a More Robust Version of Omnitest, https://github.com/swirldev/swirl/issues/196

#' Recursively expand both the correct expression and the user's expression and
#' test for a match. CAUTION: May raise errors, as in rmatch_calls.
#' 
#' @export
#' @param expr1 expression
#' @param expr2 expression
#' @param eval_for_class TRUE or FALSE. If TRUE, evaluate the first argument of an S3 method to determine its class. Default=FALSE.
#' @param eval_env parent environment for evaluations to determine class. Ignored if eval_for_class=FALSE
#' @return TRUE or FALSE according to whether expanded expressions match.
#' @examples
#' \dontrun{
#'   
#'   expr1 <- quote(print(paste("my_name_is", "mud")))
#'   expr2 <- quote(print(paste("my_name_is", "mud", sep=" ")))
#'   err <- try(ans <- is_robust_match(expr1, expr2, eval_for_class=TRUE), silent=TRUE)
#'   if(is(ans, "try-error")){
#'     ans <- isTRUE(all.equal())
#'   }
#' }
is_robust_match <- function(expr1, expr2, eval_for_class, eval_env=NULL){
  expr1 <- rmatch_calls(expr1, eval_for_class, eval_env)
  expr2 <- rmatch_calls(expr2, eval_for_class, eval_env)
  isTRUE(all.equal(expr1, expr2))
}

#' Recursively expand match calls in an expression from the bottom up.
#' 
#' Given an expression, expr, traverse the syntax tree from the
#' bottom up, expanding the call to include default values of
#' named formals as appropriate, and applying match.call to the result.
#' Functionality is limited to expressions containing ordinary functions
#' or S3 methods. If parameter eval_for_class has its default value of FALSE,
#' an error will be raised for any S3 method whose first argument (as an expression) 
#' is not atomic. If eval_for_class is TRUE, the first argument will be evaluated
#' to determine its class. Evaluation will take place in the environment given by
#' parameter eval_env. 
#' CAUTION: eval_for_class=TRUE is likely to result in multiple evaluations of the same code.
#' Expressions containing S4 or reference class methods will also raise errors.
#' @export
#' @param expr an R expression (a.k.a. abstract syntax tree)
#' @param eval_for_class TRUE or FALSE. If TRUE, evaluate the first argument of an S3 method to determine its class. Default=FALSE.
#' @param eval_env environment in which to evaluate for class. Ignored if eval_for_class=FALSE
#' @return an equivalent R expression with function or method calls in canonical form.
#' @examples
#' \dontrun{
#' 
#' # Function
#' rmatch_calls(quote(help("print")))
#' help(topic = "print", package = NULL, lib.loc = NULL, verbose = getOption("verbose"), 
#' try.all.packages = getOption("help.try.all.packages"), help_type = getOption("help_type"))
#' 
#' # S3 method with atomic first argument
#' rmatch_calls(quote(seq(0, 1, by=.5)))
#' seq(from = 0, to = 1, by = 0.5, length.out = NULL, along.with = NULL)
#' 
#' # S3 method with non-atomic first argument, eval_for_class = FALSE (default)
#' rmatch_calls(quote(seq(as.Date("2014-02-01"), as.Date("2014-03-01"))))
#' #Error in rmatch_calls(quote(seq(as.Date("2014-02-01"), as.Date("2014-03-01")))) : 
#' #  Illegal expression, seq(as.Date(x = "2014-02-01"), as.Date(x = "2014-03-01")): 
#' #  The first argument, as.Date(x = "2014-02-01"), to S3 method 'seq', is a call, 
#' #  which (as an expression) is not atomic, hence its class can't be determined in an 
#' #  abstract syntax tree without additional information.
#'  
#' # S3 method with non-atomic first argument, eval_for_class = TRUE
#' rmatch_calls(quote(seq(as.Date("2014-02-01"), as.Date("2014-03-01"))), eval_for_class=TRUE)
#' seq(from = as.Date(x = "2014-02-01"), to = as.Date(x = "2014-03-01"), 
#'     length.out = NULL, along.with = NULL)  
#' }
rmatch_calls <- function(expr, eval_for_class=FALSE, eval_env=NULL){
  # If expr is not a call, just return it.
  if(!is.call(expr))return(expr)
  # Replace expr's components with matched versions.
  for(n in 1:length(expr)){
    expr[[n]] <- rmatch_calls(expr[[n]],eval_for_class)
  }
  # If match.fun(expr[[1]]) raises an exception here, the code which follows
  # would be likely to give a misleading result. Catch the error merely to
  # produce a better diagnostic.
  tryCatch(fct <- match.fun(expr[[1]]),
           error=function(e)stop(paste0("Illegal expression ", dprs(expr), 
                                        ": ", dprs(expr[[1]]), " is not a function.\n")))
  # If fct is a special function such as `$`, or builtin such as `+`, return expr.
  if(is.primitive(fct)){
    return(expr)
  }
  # If fct is an (S4) standardGeneric, match.call is likely to give a misleading result,
  # so raise an exception. (Note that builtins were handled earlier.)
  if(is(fct, "standardGeneric")){
    stop(paste0("Illegal expression, ", dprs(expr), ": ", dprs(expr[[1]]), " is a standardGeneric.\n"))
  }
  # At this point, fct should be an ordinary function or an S3 method.
  if(isS3(fct)){
    # If the S3 method's first argument, expr[[2]], is anything but atomic 
    # its class can't be determined here without evaluation.
    if(!is.atomic(expr[[2]]) & !eval_for_class){
      stop(paste0("Illegal expression, ", dprs(expr),": The first argument, ", dprs(expr[[2]]), 
                  ", to S3 method '", dprs(expr[[1]]), 
                  "', is a ", class(expr[[2]]) , ", which (as an expression) is not atomic,",
                  " hence its class can't be determined in an abstract",
                  " syntax tree without additional information.\n"))
    }
    # Otherwise, attempt to find the appropriate method.
    if(is.null(eval_env)){
      eval_env <- new.env()
    } else {
      eval_env <- new.env(parent=eval_env)
    }
    temp <- eval(expr[[2]], envir = eval_env)
    classes <- try(class(temp), silent=TRUE)
    for(cls in classes){
      err <- try(fct <- getS3method(as.character(expr[[1]]), cls), silent=TRUE)
      if(!is(err, "try-error"))break
    }
    # If there was no matching method, attempt to find the default method. If that fails,
    # raise an error
    if(is(err, "try-error")){
      tryCatch(fct <- getS3method(as.character(expr[[1]]), "default"),
               error = function(e)stop(paste0("Illegal expression ", dprs(expr), ": ",
                                              "There is no matching S3 method or default for object, ",
                                              dprs(expr[[2]]), ", of class, ", cls,".\n")))
    }
  }
  # Form preliminary match. If match.call raises an error here, the remaining code is
  # likely to give a misleading result. Catch the error merely to give a better diagnostic.
  tryCatch(expr <- match.call(fct, expr),
           error = function(e)stop(paste0("Illegal expression ", dprs(expr), ": ", 
                                          dprs(expr[[1]]), " is not a function.\n")))
  # Append named formals with default values which are not included
  # in the preliminary match
  fmls <- formals(fct)
  for(n in names(fmls)){
    if(!isTRUE(fmls[[n]] == quote(expr=)) && !(n %in% names(expr[-1]))){
      expr[n] <- fmls[n]
    }
  }
  # match call again, for order
  expr <- match.call(fct, expr)
  return(expr)
}
# Helpers
isS3 <- function(fct)isTRUE(grep("UseMethod", body(fct)) > 0)
dprs <- function(expr)deparse(expr, width.cutoff=500)

# --- SOURCE FILE: rmd2df.R ---

# [shimmed-offline] library(stringr)

## GET CORRECT ANSWER -- GENERIC AND METHODS

get_corr_ans <- function(unit) UseMethod("get_corr_ans")

get_corr_ans.default <- function(unit) {
  NA
}

get_corr_ans.cmd_question <- function(unit) {
  # Find code chunk delimeters
  beg_chunk <- grep("```{r", unit, fixed=TRUE)
  end_chunk <- grep("^```$", unit)
  
  if(length(beg_chunk) == 0 | length(end_chunk) == 0) {
    stop("You forgot to specify the correct answer on a command question!")
  }
  
  # Capture everything in between (exclusive)
  corr_ans <- unit[seq(beg_chunk + 1, end_chunk - 1)]
  
  # Check for comments
  if(any(grepl("#", corr_ans))) {
    stop("No comments allowed in correct answer!")
  }
  # Return correct answer
  corr_ans
}

get_corr_ans.mult_question <- function(unit) {
  corr_ans_ind <- grep("^_[1-9][.].+_$", unit)
  if(length(corr_ans_ind) == 0) {
    stop("You forgot to specify the correct answer on a multiple choice question!")
  }
  gsub("^_[1-9][.]\\s|_$", "", unit[corr_ans_ind])
}

## GET ANSWER CHOICES -- GENERIC AND METHODS

get_ans_choices <- function(unit) UseMethod("get_ans_choices")

get_ans_choices.default <- function(unit) {
  NA
}

get_ans_choices.mult_question <- function(unit) {
  # Find answer choices
  choice_ind <- grep("^_?[1-9][.]", unit)
  if(length(choice_ind) == 0) {
    stop("You forgot to specify answer choices!")
  }
  # Collapse answer choices
  collapse_choices(unit[choice_ind])
}

## GET ANSWER TESTS -- GENERIC AND METHODS

get_ans_tests <- function(unit) UseMethod("get_ans_tests")

get_ans_tests.default <- function(unit) {
  NA
}

get_ans_tests.cmd_question <- function(unit) {
  ans_tests_ind <- grep("*** .ans_tests", unit, fixed = TRUE) + 1
  if(length(ans_tests_ind) == 0) {
    #warning("No answer tests specified for a command question!")
    return(paste0("omnitest(correctExpr=\'", get_corr_ans(unit), "\')"))
  }
  unit[ans_tests_ind]
}

get_ans_tests.mult_question <- function(unit) {
  paste0("omnitest(correctVal=\'", get_corr_ans(unit), "\')")
}

## GET HINT -- GENERIC AND METHODS

get_hint <- function(unit) UseMethod("get_hint")

get_hint.default <- function(unit) {
  NA
}

get_hint.cmd_question <- function(unit) {
  hint_ind <- grep("*** .hint", unit, fixed = TRUE) + 1
  if(length(hint_ind) == 0) stop("You forgot to specify a hint!")
  hint <- unit[hint_ind]
}

get_hint.mult_question <- function(unit) {
  hint_ind <- grep("*** .hint", unit, fixed = TRUE) + 1
  if(length(hint_ind) == 0) stop("You forgot to specify a hint!")
  hint <- unit[hint_ind]
}

## GET FIGURE FILENAME AND TYPE -- GENERIC AND METHODS

get_fig_filename <- function(unit) UseMethod("get_fig_filename")

get_fig_filename.default <- function(unit) {
  NA
}

get_fig_filename.figure <- function(unit) {
  fig_ind <- grep("*** .figure", unit, fixed = TRUE) + 1
  if(length(fig_ind) == 0) stop("You forgot to specify a figure filename!")
  fig <- unit[fig_ind]
}

get_fig_type <- function(unit) UseMethod("get_fig_type")

get_fig_type.default <- function(unit) {
  NA
}

get_fig_type.figure <- function(unit) {
  figtype_ind <- grep("*** .fig_type", unit, fixed = TRUE) + 1
  if(length(figtype_ind) == 0) stop("You forgot to specify a figure type!")
  figtype <- unit[figtype_ind]
}

## GET VIDEO URL -- GENERIC AND METHODS

get_video_url <- function(unit) UseMethod("get_video_url")

get_video_url.default <- function(unit) {
  NA
}

get_video_url.video <- function(unit) {
  vid_ind <- grep("*** .video_url", unit, fixed = TRUE) + 1
  if(length(vid_ind) == 0) stop("You forgot to specify a video URL!")
  vid <- unit[vid_ind]
}

## MAKE ROW

make_row <- function(unit) {
  output <- unit[2]
  corr_ans <- get_corr_ans(unit)
  ans_choices <- get_ans_choices(unit)
  ans_tests <- get_ans_tests(unit)
  hint <- get_hint(unit)
  fig <- get_fig_filename(unit)
  fig_type <- get_fig_type(unit)
  vid_link <- get_video_url(unit)
  
  c(Class = class(unit), Output = output, CorrectAnswer = corr_ans,
       AnswerChoices = ans_choices, AnswerTests = ans_tests, Hint = hint,
       Figure = fig, FigureType = fig_type, VideoLink = vid_link)
}

## UTILITIES

# Return indices of YAML
yaml_ind <- function(rmd) {
  yaml_end <- min(grep("=======", rmd, value=FALSE))
  seq(1:yaml_end)
}

#' @importFrom yaml yaml.load
get_yaml <- function(rmd) {
  # Find index of end of YAML
  yaml_end <- max(yaml_ind(rmd))
  
  # Return lesson metadata
  sapply(seq(1, yaml_end - 1), function(i) yaml.load(rmd[i]))
}

clean_me <- function(rmd) {
  # Remove leading and trailing whitespace
  rmd_clean <- str_trim(rmd)
  
  # Remove empty lines
  rmd_clean <- rmd_clean[which(rmd_clean != "")]
  
  # Get rid of yaml
  rmd_clean[-yaml_ind(rmd_clean)]
}

into_units <- function(rmd) {
  # Separate rmd into groups based on units of instruction
  unit_num <- cumsum(str_detect(rmd, "^---"))
  
  # Return list of units
  split(rmd, unit_num)
}

get_unit_class <- function(unit) {
  cl <- str_split_fixed(unit[1], "&", 2)[2]
  valid_classes <- c("text",
                     "cmd_question",
                     "mult_question",
                     "video",
                     "figure")
  if(!cl %in% valid_classes) stop("Invalid unit class used!")
  cl
}

collapse_choices <- function(choices) {
  no_num <- gsub("^_?[1-9][.]\\s|_?$", "", choices)
  paste(no_num, collapse = "; ")
}

rmd2df <- function(rmd_path) {
  my_rmd <- readLines(rmd_path, warn=FALSE)
  # Get metadata from yaml - set as lesson attributes below
  meta <- get_yaml(my_rmd)
  cleaned <- clean_me(my_rmd)
  units <- into_units(cleaned)
  classes <- lapply(units, get_unit_class)
  units_with_class <- mapply(`class<-`, units, classes)
  rows <- sapply(units_with_class, make_row)
  
  # Assemble content data frame
  df <- as.data.frame(t(rows), stringsAsFactors=FALSE)
  
  # Return object of class "lesson"
  lesson(df, lesson_name=meta$`Lesson Name`, course_name=meta$`Course Name`,
         author=meta$Author, type=meta$Type, organization=meta$Organization,
         version=meta$Version)
}

# --- SOURCE FILE: testthat_legacy.R ---

# The versions of the functions below have been graciously borrowed
# from version 0.11.0 of the testthat package by 
# Hadley Wickham and others at RStudio. These APIs
# were broken in later versions of testthat and we know the
# old version works for our purposes.

expectation_legacy <- function(passed, failure_msg, 
                            success_msg = "unknown", 
                            srcref = NULL) {
  structure(
    list(
      passed = passed,
      error = FALSE,
      skipped = FALSE,
      failure_msg = failure_msg,
      success_msg = success_msg,
      srcref = srcref
    ),
    class = "expectation"
  )
}

#' @importFrom testthat compare
equals_legacy <- function(expected, label = NULL, ...) {
  if (is.null(label)) {
    label <- findExpr("expected")
  } else if (!is.character(label) || length(label) != 1) {
    label <- deparse(label)
  }
  
  function(actual) {
    same <- compare(actual, expected, ...)
    
    expectation_legacy(
      same$equal,
      paste0("not equal to ", label, "\n", same$message),
      paste0("equals ", label)
    )
  }
}

is_a_legacy <- function(class) {
  function(x) {
    actual_s <- paste0(class(x), collapse = ", ")
    class_s <- paste(class, collapse = ", ")
    expectation_legacy(
      inherits(x, class),
      paste0("inherits from ", actual_s, " not ", class_s),
      paste0("inherits from ", class_s)
    )
  }
}

is_equivalent_to_legacy <- function(expected, label = NULL) {
  if (is.null(label)) {
    label <- findExpr("expected")
  } else if (!is.character(label) || length(label) != 1) {
    label <- deparse(label)
  }
  function(actual) {
    equals_legacy(expected, check.attributes = FALSE)(actual)
  }
}

is_identical_to_legacy <- function(expected, label = NULL) {
  if (is.null(label)) {
    label <- findExpr("expected")
  } else if (!is.character(label) || length(label) != 1) {
    label <- deparse(label)
  }
  
  function(actual) {
    if (identical(actual, expected)) {
      diff <- ""
    } else {
      same <- all.equal(expected, actual)
      if (isTRUE(same)) {
        diff <- "Objects equal but not identical"
      } else {
        diff <- paste0(same, collapse = "\n")
      }
    }
    
    expectation_legacy(
      identical(actual, expected),
      paste0("is not identical to ", label, ". Differences: \n", diff),
      paste0("is identical to ", label)
    )
  }
}

matches_legacy <- function(regexp, all = TRUE, ...) {
  stopifnot(is.character(regexp), length(regexp) == 1)
  function(char) {
    matches <- grepl(regexp, char, ...)
    if (length(char) > 1) {
      values <- paste0("Actual values:\n",
                       paste0("* ", encodeString(char), collapse = "\n"))
    } else {
      values <- paste0("Actual value: \"", encodeString(char), "\"")
    }
    
    expectation_legacy(
      length(matches) > 0 && if (all) all(matches) else any(matches),
      paste0("does not match '", encodeString(regexp), "'. ", values),
      paste0("matches '", encodeString(regexp), "'")
    )
  }
}

# Configure default offline paths
options(
  swirl_courses_dir = file.path(.aargh_root, "courses"),
  swirl_data_dir    = file.path(.aargh_root, "swirl_inst", "user_data"),
  swirl_language    = "english",
  swirl_logging     = FALSE
)

