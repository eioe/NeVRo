
<h2>Using EEG to Decode Subjective Levels of Emotional Arousal during an Immersive VR Roller Coaster Ride</h2>

This pipeline is archived for the sake of completeness. This is the code which was used to produce the results reported in Klotzsche (2018) [IEEEVR conference Poster/mini proceedings paper]. This code has been "deprecated" and is not maintained. 
As long as you do not just want to reproduce the results of this very poster/paper, you are better off with the newer NeVRo pipeline (see `master`branch or https://github.com/SHEscher/NeVRo). It's (slightly) better code and preprocessing - and (way better!) documentation.

However, if you want to get this code to run, please go for it. If there are problems/unclarities (which is unfortunately very likely to be the case), do not hesitate to get in touch with me: 

klotzsche [at] cbs[.]mpg[.]de

It would have been better to write the code directly in a sustainable version, I know. But it was 2017 and I needed to finish my Masters and start my PhD. Bear with me. 
Once we decided to publish it, I decided it's better to start a new repo "from scratch" with the collaborators. So this one got neglected. 
Anyway, together we will also make this work. :) 

Felix Klotzsche, 2020

<h2>Introduction</h2>

We used virtual reality (VR) to investigate emotional arousal under naturalistic conditions. 45 subjects experienced virtual roller coaster rides while their neural (EEG) and peripheral physiological (ECG, GSR) responses were recorded. Afterwards, they rated their subject levels of arousal retrospectively on a continuous scale while viewing a recording of their experience.

<h3>CSP Model</h3>
<a href="https://ieeexplore.ieee.org/document/4408441/">Common Spatial Pattern (CSP)</a> algorithm derives a set of spatial filters to project the EEG data onto compontents whose band-power maximally relates to the prevalence of specified classes (here low and high arousal).<br>
<br>
This part of the study was published at IEEE VR 2018 in Reutlingen, Germany:<br>
<a href="https://ieeexplore.ieee.org/abstract/document/8446275"> Klotzsche, Mariola, Hofmann, Nikulin, Villringer, & Gaebler. <i>IEEE VR</i>, 2018.</a>

<h3>Collaborators</h3>
<a href="https://github.com/SHEscher">Simon M. Hofmann</a><br>
<a href="https://github.com/eioe">Felix Klotzsche</a><br>
<a href="https://github.com/langestroop">Alberto Mariola</a>
