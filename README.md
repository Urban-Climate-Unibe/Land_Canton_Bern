%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Introduction %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\section{Background and Motivation}\label{Introduction}
Anthropogenic climate change is expected to increase the amount, intensity, and duration of heat waves. The urban heat island (UHI) effect further amplifies this trend in urban environments \citep{Burger:2021jd, Gubler:2021jd, Wicki:2018jd}. The UHI effect is expressed by higher air temperatures in urban areas compared to rural areas in the region \citep{Oke:2006}. The effect is highest during night, as the emission of longwave radiation in urban environments is impaired and sensible heat fluxes are enhanced, whilst latent fluxes are reduced \citep{Burger:2021jd, Gubler:2021jd}. People living in urban areas are thus highly affected by the UHI effect via thermal stress \citep{Burger:2021jd, Wicki:2018jd}. Given that more than 75 \% of the Central European population lives in urban areas, the increasing trend poses one of the major weather threats to people in urban environments \citep{Wicki:2018jd}. Studying spatial temperature variabilities in urban areas is therefore crucial to implement adaptation measures to minimize effects on human health and the environment \citep{Burger:2021jd}.\newline

\noindent To capture small-scale temperature changes in these climatically complex areas, high spatial resolution measurement networks are needed. However, automated weather stations (AWS) are scarce due to their high costs. To tackle this problem,  \citet{Gubler:2021jd} developed a new type of low-cost measurement devices (LCDs). The LCD consists of a temperature logger and a custom-made radiation shield that is naturally ventilated. 79 LCDs were installed in the city of Bern, Switzerland \citep{Gubler:2021jd}. \citet{Gubler:2021jd} reported an overestimation of hourly mean temperature measurements by the LCDs (0.61 °C to 0.93 °C) compared to the reference stations (AWS) during daytime (06:00 – 22:00). During night-time (22:00 – 06:00), differences were much lower or even negative (-0.12 to 0.23 °C). But not only the LCD temperature and the anomaly between the LCDs and the AWS is interesting, but also the temperature distribution of the entire region of Bern, shown on a map.\newline

\noindent \citet{Tinner:2023jd} created a map of the distribution of temperatures in Bern for the current logger temperatures. This predicts the local temperature based on land use data as demonstrated by \citet{Burger:2021jd}. The approach used by \citet{Burger:2021jd} is a multivariate linear regression Model. As the model only knows the current temperature distribution, its scope and statistical power are limited. This project aims to compare different machine learning techniques to a multivariate linear regression model for land use classes and meteorologic data, thus using collected data from the past four years of meteorological and logger measurements to train the models. Furthermore, this project aims to not only model the temperature as good as possible but maybe also use it to show (possible future) temperature distributions by given meteorologic data.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\section{Objective}\label{Data and Methodology}
The goal of this project is to substantially improve the automatically generated temperature map based on an \href{https://github.com/sundin01/AGDS_Bigler_Tinner/tree/main/vignettes}{algorithm} by \citealp{Tinner:2023jd}. Furthermore, we want to demonstrate that machine learning is superior to multivariate linear regression. To quantify the quality of the models, we calculate the bias (for accuracy) and the MSE (for precision) for each model. We use the coefficient of determination $R^2$ to quantify what percentage of the total variance our models explain. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\section{Implementation}
\subsection{Data}
First, we want to introduce the source of the data we will use in this project. Because our project's basis is the model of \citet{Tinner:2023jd}, we use data for the years 2019-2022 from the network of the city of Bern. This is a numerical data set of the 2m temperature in about 80 locations, with a temporal resolution of 15 minutes for all LCDs. To improve the model of \citet{Tinner:2023jd}, we use additional data from the AWS at Zollikofen. For that we have ordered data from Meteo Schweiz. Now, we have access to seven meteorological variables (2m temperature, air pressure,  relative humidity, global radiation, precipitation, wind speed, wind direction) with a temporal resolution of 10 minutes for the years 2019-2022. Further, we use the timestamp and the coordinates of Zollikofen. Because we want to capture small-scale temperature changes in a climatically complex area, we think knowledge about the land use is important. That is why we have access to 60 land use classes. The land use classes is a raster data set, where a numerical value is assigned in each pixel. Unfortunately, we do not know the original source. Since our secondary source is known and we trust him, we start our project anyway. But we will try to be able to specify the original source in our final workflow. Table 1 provides a brief overview of the data we will use. 

\begin{table}[H]\label{table: Location and Data}
    \caption{The table shows all the data which will be used in this project. Click on the source to get access to the raw data of this project}
    \centering
\small
\begin{tabular}{ @{}l l l l l}
\toprule
Source & Type & Kind of data & Resolution & Period \\
\midrule

\href{https://github.com/sundin01/AGDS_Bigler_Tinner/tree/main/data/Measurements}{Network} 
 & Numeric & 3m temperature, coordinates & 15 min & 2019-2022\\
 
\href{https://github.com/sundin01/AGDS_Bigler_Tinner/tree/main/data/Meteoswiss}{Meteo Schweiz}  & Numeric & Meteorological Variable and coordinates & 10 min & 2019-2022   \\

\href{https://github.com/sundin01/AGDS_Bigler_Tinner/tree/main/data/Tiffs}{Burger et al.} & Raster & 60 different Land Use Classes & different & - \\

\bottomrule
\end{tabular}
\end{table}

\clearpage

\subsection{Methodology}
\noindent The data of the years 2019 until 2022 of the urban climate measurement network of the city of Bern is read in and combined with metadata to locate the measurements. This data is combined with the appropriate land use values. It is not yet clear what exact land use values will be used for the model. These will be determined by comparing influence to runtime of the model. Then meteorologic values are added to each measurements. Now, the models are trained on the years 2020 to 2022 and the year 2019 will be used as a validation year. We will do this for a multivariate linear regression model, a KNN model and a random forest model. If we have time left, we will also try to calculate a neronal network model. Because both of us do not have any experience with that, we do not know whether we will able to do this.\newline

\noindent As a visualization of the model, a map is then be rendered by combining the land use layers with meteorologic data. The model uses the locations of LCDs as kind of a reference values. Therefore, the temperature of a arbitrary point between two LDCs depends on the numerical values of the land use layers. If we run our code, then we obtain live data from the network as an input for our models. Based on this the model calculates the temperature distribution for the city of Bern. It will be also possible to give an input manually. This gives us the opportunity to get a glimpse into a possible future. Finally, we will determine the $R^2$, bias, and MAE for each model and use them to compare the models.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Responsibilities and Timeline %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\section{Responsibilities and Timeline}
For our project, we split the responsibility for each task. But this does not mean that the responsible person works alone. All decisions are based on a collaborative exchange. Table 2 shows the tasks and who is responsible for them. 

\begin{table}[H]\label{table: Location and Data}
    \caption{The table shows the distribution of tasks. The listed person has the leadership for the respective task. However, the result is based on an equal professional exchange}
    \centering
\small
\begin{tabular}{ @{}l l l}
\toprule
Who & Task & Deadline \\
\midrule
Both & Exchange so that both are on the same level of knowledge & Week 40  \\
Both & Write a proposal & Week 41 \\
Staff & Meeting with the staff to discuss the proposal & Week 41 \\
Both & revise the proposal & Week 42 \\
Both & Stepwise regression and decide which land use classes we use& Week 43  \\
Nils & Random Forest & Week 45  \\
Patrick & Regression and linear Regression model & Week 45 \\
Patrick & KNN & Week 45 \\
Both & Neuronal network (if possible)  & Week 48 \\
Both & Write and test the reproducible workflow & Week 48 \\
\bottomrule
\end{tabular}
\end{table}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Risks and Contingency %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\vspace{-4mm}
\section{Risks and Contingency}

\begin{itemize}
    \item Data loss and technical issues:
To minimize the chance of data loss or technical issues all code and implementations as well as all data is backed up to github. If the data becomes to large there should either be an R-Script that generates the file or the file should be backed up onto external sources.
\item Issues with coding:
In case we face severe issues with the implementation, the staff panel will be consulted.

\item It is possible that we are not able to create a neuronal network

\end{itemize}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Impact %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\vspace{-4mm}
\section{Impact}

Ideally, we can show that machine learning approaches are superior to classical linear regressions and therefore it is reasonable to implement them. Moreover, the generated model will be able to calculate the temperature of a given site based on land use and meteorologic data. This could be used for three things: First, one can  calculate the temperature of the past, the present or the future. One could for example look at the heat of Bern during the last 100 years or use the predictions of MeteoSwiss to predict the urban heat island in the future if all variables are available. This could be of societal relevance since heat is a concern in cities especially with climate change. Second, a warning system could be implemented and warn people in affected areas. Third, one could also assess the excess deaths during the summer months of the past few decades by calculating the heat distribution of past summer nights and so better the understanding of heat deaths. These are just some of the possibilities a new model would offer.
