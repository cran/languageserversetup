#' Install the `languageserver` package to a separate library
#'
#' @param rlsLib `character(1)` path to the library.
#' @param strictLibrary `logical(1)` if `TRUE`, all the dependencies
#'   of `languageserver` will be installed into `rlsLib`, otherwise
#'   only those that are needed but not present in other libraries
#'   in `.libPaths()` will be installed.
#' @param fullReinstall `logical(1)`. If `TRUE`, `rlsLib` will be
#'   recursively removed to re-install all the packages cleanly.
#' @param fromGitHub `logical(1)`, if `TRUE`, will use
#'   `remotes::install_github()`, otherwise `install.packages()` is
#'   used to install the `languageserver` package.
#' @param confirmBeforeInstall `logical(1)` if `TRUE`, will ask the
#'   user to confirm the steps before installation. For non-interactive
#'   use, `FALSE` will skip the confirmation.
#' @param dryRun `logical(1)`, if `TRUE`, most actions will only be
#'   reported, not taken - nothing will be removed, created or installed.
#'
#' @importFrom utils install.packages
#'
#' @return side-effects
#' @export
languageserver_install <- function(
  rlsLib = getOption("langserver_library"),
  strictLibrary = TRUE,
  fullReinstall = TRUE,
  fromGitHub = TRUE,
  confirmBeforeInstall = TRUE,
  dryRun = FALSE
) {

  sysDepAvailable <- system_dep_available()
  if (!sysDepAvailable) stop(attr(sysDepAvailable, "msg"))

  oldLibPaths <- .libPaths()
  lg("langserver_install Starting")
  on.exit({
    assign(".lib.loc", oldLibPaths, envir = environment(.libPaths))
    lg("langserver_install Exiting")
  })

  continue <- if (isTRUE(confirmBeforeInstall)) {
    try(askYesNo( # nocov start
      paste(
        "This will attempt to use remotes::install_github",
        "to install REditorSupport/languageserver into:",
        rlsLib,
        if (isTRUE(strictLibrary))
          "All dependencies will also be installed there"
        else
          "only installing unavailable dependencies",
        if (isTRUE(fullReinstall))
          paste("! The directory", rlsLib, "will be RECURSIVELY REMOVED !"),
        "Do you agree?",
        sep = "\n"
      ),
      default = FALSE
    )) # nocov end
  } else {
    TRUE
  }

  if (!isTRUE(continue)) {
    message(confirm_message())
    return(FALSE)
  }

  newLibLoc <- if (isTRUE(strictLibrary)) {
    c(rlsLib, .libPaths()[length(.libPaths())])
  } else {
    c(rlsLib, .libPaths())
  }
  lg("determined new .lib.loc: ", toString(newLibLoc))

  if (isTRUE(fullReinstall)) {
    if (isTRUE(dryRun)) {
      lg(
        "this is a dryRun, would run: ",
        "unlink(rlsLib, recursive = TRUE, force = TRUE)"
      )
    } else {
      lg("fullReinstall is TRUE, deleting ", rlsLib)
      unlink(rlsLib, recursive = TRUE, force = TRUE)
    }
  }
  if (!dir.exists(rlsLib)) {
    if (isTRUE(dryRun)) {
      lg(
        "this is a dryRun, would run: ",
        "dir.create(rlsLib, recursive = TRUE)"
      )
    } else {
      lg("rlsLib does not exist, creating ", rlsLib)
      dir.create(rlsLib, recursive = TRUE)
    }
  }

  lg("assigning ", newLibLoc, " to .lib.loc")
  assign(".lib.loc", newLibLoc, envir = environment(.libPaths))

  if (isTRUE(fromGitHub)) {
    if (isTRUE(dryRun)) {
      lg("this is a dryRun, would run remotes::install_github")
      return("remotes::install_github")
    }
    lg("running dev installation")
    source( # nocov start
      "https://install-github.me/REditorSupport/languageserver"
    ) # nocov end
  } else {
    if (isTRUE(dryRun)) {
      lg("this is a dryRun, would run utils::install.packages")
      return("utils::install.packages")
    }
    lg("running install.packages")
    utils::install.packages( # nocov start
      pkgs = "languageserver",
      lib = rlsLib
    ) # nocov end
  }
}