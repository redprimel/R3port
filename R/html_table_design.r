#------------------------------------------ html_table_design ------------------------------------------
#' Designs a table based on a object returned by the table_prep function
#'
#' This function designs the a HTML table based on the data frame list returned by the table_prep function.
#'
#' @param dfl list generated by the table_prep function which serves as the base of the table to be generated
#' @param uselabel logical indicating if labels should be used for the x variable(s).
#'    If set to TRUE, the function will try to use the label attribute for the display of x variable(s).
#' @param yhead logical indicating if the y variable should also be set as header in the table.
#' @param footnote character string with the footnote to be placed in the footer of the page (HTML coding can be used for example to create line breaks)
#' @param title character string to define the title of the table which will be added to the caption
#' @param titlepr character string to define the prefix of the table title. Can be used to create custom table numbering
#' @param xabove logical indicating if the first unique x variable should be placed in the table row above. Mostly used to save space on a page
#' @param group number indicating which x variables should be grouped (displayed in table with a certain white space) and interpreted as x[1:group]
#' @param xrepeat logical indicating if duplicate x values should be repeated in the table or not
#' @param tclass character string with the table class. Can be used in combination with custom css
#'
#' @details This function designs a HTML pivot table based on the results of the table_prep output. This means that the function
#'   Should always be used in conjunction with this function.
#' @return The function returns a vector that defines the entire HTML table. This vector can be adapted manually
#'   however it is intended to be used in a print function to add to a HTML document.
#'
#' @export
#' @examples
#'
#' \dontrun{html_table_design(lstobject)}
html_table_design <- function(dfl,uselabel=TRUE,yhead=FALSE,footnote=NULL,title="table",titlepr=NULL,
                              xabove=TRUE,group=NULL,xrepeat=FALSE,tclass="sample"){

  # Create pre-table attributes
  tbl <- NULL
  tbl <- c(tbl,paste("<h1>",titlepr,title,"</h1>"))
  tbl <- c(tbl,paste0("<table class='",tclass,"'>"))

  # Create header (check for future if hdr can be provided as argument (to create non standard tables))
  hdrl <- plyr::llply(1:length(dfl$tblo$y),function(num){
    hdrd <- dfl$tblh
    hdrd <- hdrd[!duplicated(do.call("paste",hdrd[1:num])),]
    hdr  <- NULL
    if(yhead==TRUE){
      ylb <- dfl$tblo$y[num]
      if(uselabel) ylb <- ifelse(is.null(attr(dfl$odata[,ylb],'label')),ylb,attr(dfl$odata[,ylb],'label'))
      hdr <- c(hdr,paste0("<tr><td colspan='",ncol(dfl$tbld),"'></td></tr>"))
      hdr <- c(hdr,paste0("<tr>",paste(rep("<td></td>",length(dfl$tblo$x)),collapse="")))
      hdr <- c(hdr,paste0("<td id='fht' colspan='",sum(hdrd[,paste0("yn",num)]),"'>",dfl$tblo$y[num],"</td></tr>"))
      hdr <- c(hdr,paste0("<tr><td colspan='",ncol(dfl$tbld),"'></td></tr>"))
    }
    if(num!=length(dfl$tblo$y)){
      hdr <- c(hdr,paste0("<tr><td colspan='",ncol(dfl$tbld),"'></td></tr>"))
      hdr <- c(hdr,paste0("<tr>",paste(rep("<td></td>",length(dfl$tblo$x)),collapse="")))
      hdr <- c(hdr,paste(paste("<td id='fh' colspan='",hdrd[,paste0("yn",num)],"'>",hdrd[,paste0("y",num)],"</td>",collapse="",sep=""),"</tr>"))
      hdr <- c(hdr,paste0("<tr><td colspan='",ncol(dfl$tbld),"'></td></tr>"))
    }else{
      xlb <- dfl$tblo$x
      if(uselabel) xlb <- sapply(xlb,function(lbls) ifelse(is.null(attr(dfl$odata[,lbls],'label')),lbls,attr(dfl$odata[,lbls],'label')))
      hdr <- c(hdr,paste0("<tr>",paste("<td id='lhfcol'>", xlb ,"</td>",collapse="")))
      hdr <- c(hdr,paste0(paste("<td id='lh'>",hdrd[,paste0("y",num)],"</td>",collapse=""),"</tr>"))
    }
    return(hdr)
  })
  tbl <- c(tbl,unlist(hdrl))

  # Add data and close off
  # Create character for all variables to overcome problems with invalid factor levels
  dfl$tbld[] <- apply(dfl$tbld,2,as.character)
  dup1 <- !duplicated(dfl$tbld[,dfl$tblo$x[1]])
  if(!is.null(group)) dup2 <- !duplicated(dfl$tbld[,1:group,drop=FALSE],fromLast=TRUE)
  if(!xrepeat){
    duplst <- plyr::llply(1:length(dfl$tblo$x),function(coln){duplicated(do.call("paste",dfl$tbld[,1:coln,drop=FALSE]))})
    plyr::l_ply(1:length(duplst),function(coln){dfl$tbld[unlist(duplst[coln]),coln] <<- ""})
  }

  dtal <- plyr::llply(1:nrow(dfl$tbld),function(num){
    if(xabove & dup1[num]==TRUE){
      dta <- paste0("<tr><td id='xabove' colspan='",ncol(dfl$tbld),"'>",dfl$tbld[num,1],"</td></tr>")
      if(length(dfl$tblo$x)==1){
        dta <- c(dta,"<tr><td></td>")
      }else{
        dta <- c(dta,paste0("<tr><td></td>",paste("<td id='fcol'>",dfl$tbld[num,2:length(dfl$tblo$x)],"</td>",collapse="")))
      }
      dta <- c(dta,paste0(paste("<td>",dfl$tbld[num,(length(dfl$tblo$x)+1):ncol(dfl$tbld)],"</td>",collapse=""),"</tr>"))
    }else{
      dta <- paste0("<tr>",paste("<td id='fcol'>",dfl$tbld[num,1:length(dfl$tblo$x)],"</td>",collapse=""))
      dta <- c(dta,paste0(paste("<td>",dfl$tbld[num,(length(dfl$tblo$x)+1):ncol(dfl$tbld)],"</td>",collapse=""),"</tr>"))
    }
    if(!is.null(group)){if(dup2[num]==TRUE) dta <- c(dta,paste0("<tr><td id='grps' colspan='",ncol(dfl$tbld),"'></td></tr>"))}
    return(dta)
  })
  tbl <- c(tbl,unlist(dtal),"</table>")
  if(!is.null(footnote)) tbl <- c(tbl,footnote)
  tbl <- c(tbl,"</br></br>")
  return(tbl)
}
