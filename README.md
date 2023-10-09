% Copyright by Patrick Bigler. 
% If you want to use this template, please ask for permission: 
% patrick.bigler1@students.unibe.ch or paedy87@gmail.com

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\documentclass[12pt, a4paper]{article}
%-------------------------------------------------------------------------------
% font, language, margins etc...
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc} % special characters
\usepackage{setspace} % double or single space
\usepackage{siunitx} % provide a possibility to deal with SI units
\usepackage{fancyhdr} % provide a possibility to deal with header and footer
\usepackage[left=2.5cm, right=2.5cm, top=2.3cm, bottom=2.3cm]{geometry} % set margins
\usepackage[cbgreek]{textgreek} % provides greek letters outside math mode

%-------------------------------------------------------------------------------
% bibliography
\usepackage[round]{natbib} % create own bibliography (APA Sytle)
\usepackage[nottoc,numbib]{tocbibind} % Bibliography appears in toc
\DeclareRobustCommand{\firstsecond}[2]{#1} % special citation (@misc in natbib)
\usepackage{doi}
%-------------------------------------------------------------------------------
% abstract
\usepackage{abstract}

%-------------------------------------------------------------------------------
% Table of Contnets
\renewcommand{\contentsname}{Table of Contents} % Change name of ToC

%-------------------------------------------------------------------------------
% tables
\usepackage{multicol}
\usepackage[table,xcdraw]{xcolor}
\usepackage{multirow}
\usepackage{colortbl}
\usepackage{caption}
\usepackage{subcaption}
\usepackage[font=footnotesize]{caption}
\usepackage{booktabs} % design the table with toprule, midrule and bottomrule

%-------------------------------------------------------------------------------
% figures
\usepackage{graphicx}
\usepackage{float}
\usepackage{wrapfig}

%-------------------------------------------------------------------------------
% mathematics
\usepackage{mathtools}

%-------------------------------------------------------------------------------
% SI unit
\usepackage{siunitx} 

%-------------------------------------------------------------------------------
% chemistry
\usepackage{mhchem}

%-------------------------------------------------------------------------------
% read programming like R or Python
\usepackage{listings}

%-------------------------------------------------------------------------------
% link (internal & external)
\usepackage{xurl}
\usepackage[colorlinks=true, citecolor = red, linkcolor = blue, linkref=none]{hyperref}

%-------------------------------------------------------------------------------
% setlenghts & new commands
% \setlength{\arrayrulewidth}{0.5mm}
% \setlength{\tabcolsep}{18pt}
% \setlength\parindent{0pt}
%\DeclareRobustCommand{\firstsecond}[2]{#1}

%\renewcommand{\abstractnamefont}{\normalfont\bfseries}
%\renewcommand{\abstracttextfont}{\normalfont\small}
%\renewcommand{\arraystretch}{1.5}

\onehalfspacing % line space 1.5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin document %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\begin{document}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Introduction %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\input{Chapters/00_titlepage}


%-------------------------------------------------------------------------------
% roman page numbers: I, II, III, IV, V, ...
%\pagenumbering{Roman} 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Praemble %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%\input{Chapters/0_praeamle}

%-------------------------------------------------------------------------------
% start with a new page
%\newpage

%-------------------------------------------------------------------------------
% arabic page numbers: 1, 2, 3, 4, 5,...
\pagenumbering{arabic} 

%-------------------------------------------------------------------------------
% header and foot settings
\pagestyle{fancy}
\fancyhf{}
\fancyhead[R]{\rightmark}
\fancyhead[L]{\leftmark}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.2pt}
\renewcommand{\footrulewidth}{0.2pt}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data and Methodology %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\input{Chapters/01_proposal}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% References %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------------------------------------------------
% line space 1
\begin{singlespace}

%-------------------------------------------------------------------------------
% add bibliography
\nocite{*}
\bibliographystyle{agsm} % Harvard style citation
\bibliography{biblio} % do not change the name (if you want to, please change the name in the outline as well!

\end{singlespace}

\end{document}

