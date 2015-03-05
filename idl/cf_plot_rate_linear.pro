;+
;  cf_plot_rate_linear.pro is a procedure to plot the count rate and screening 
;			as a function of time for calfuse 3.0 data. 
;		THIS VERSION PRODUCES A LINEAR PLOT OF COUNT RATE
;
;  Author:  Edward M. Murphy
;  Written: 2000 April 21
;
;       Calling sequence: cf_plot_rate3, rootname
;
;       Inputs:    rootname will have 'idf.fit' added to it.
;
; 02/20/03 JC Hsu      Adapt from cf_plot_rate.pro to work on version 3.0 data.
; 05/17/04 V Dixon     Adapt from cf_plot_rate3.pro
;-

pro cf_plot_rate_linear, rootname

	!quiet=1

	; Open input IDF file
	filename=rootname+'idf.fit'
	dummy=mrdfits(filename,0,ah,/SILENT)

	; Read primary header keywords
	pdate = fxpar(ah,'DATE')
	dateobs = fxpar(ah,'DATEOBS')
	expstart = fxpar(ah,'EXPSTART')
	expend = fxpar(ah,'EXPEND')
	detector = fxpar(ah,'DETECTOR')

	exposure = (expend - expstart) * 24. * 3600.

	; Define plot attributes.
	!p.multi=[0,1,2]
	set_plot,'Z'
	device,set_resolution=[1024,512]

	!x.style=1
	!y.style=1
	!x.tickformat='(I6)'

	!x.title="Time (seconds)"
	!y.title="Count rate"
	!p.charsize=1.2
	!p.background=255
	!p.color=0

	; Read columns from the timeline extension (ext 3)
	ftab_ext, filename, 'TIME', time0, exten_no=3
	ftab_ext, filename, 'STATUS_FLAGS', flags, exten_no=3
	time = [0, time0, exposure]

	; Compute the day/night screenings (bit 1)
	flags1 = ishft(flags, 7) 
	flags1 = ishft(flags1, -7) ; only keep bit 1

	; Compute the limb angle screening (bit 2)
	flags2 = ishft(flags, 6) ;
	flags2 = ishft(flags2, -7) ; only keep bit 2

	; Compute the SAA screening (bit 3)
	flags3 = ishft(flags, 5) ;
	flags3 = ishft(flags3, -7) ; only keep bit 3

	; Compute burst screening (bit 5)
	flags5 = ishft(flags, 3) ;
	flags5 = ishft(flags5, -7) ; only keep bit 5

	; Compute jitter screening (bit 7)
	flags7 = ishft(flags, 1) ;
	flags7 = ishft(flags7, -7) ; only keep bit 7

	ftab_ext, filename, 'BKGD_CNT_RATE', bkgd, exten_no=3
	len = size(time0)
	packet = 1 > len[1]/100 ; determine rebinning size
	wht = where(time0 eq time0)
	whbin = where(wht mod packet eq 0)

	for i = 1, 2 do begin

		if (i eq 1) then text = ' LiF' else text = ' SiC'
		!p.title=filename + text

		; Plot the count rate
		if (i eq 1) then col = 'LIF' else col = 'SIC'
		ftab_ext, filename, col+'_CNT_RATE', crate, exten_no=3
		ymax = max(crate)*1.2
		ymin = 0.
		!y.range=[ymin, ymax]
		plot, time0, crate, xr=[0,exposure], linestyle=0, psym=10
		oplot, time0(whbin), bkgd(whbin)*(10./i), linestyle=1
		if (i eq 1) then text = '5' else text = '10'
		xyouts,exposure/50,ymax/20,'BKGD scaled by '+text,charsize=1
		
	
		; Shade day/night screenings
		;;;flags11 = flags1 * (-0.2*ymin) + ymin
		;;;flags11 = [0, flags11, 0]
		flags11 = flags1 * (0.025*ymax) + ymax
		flags11 = [ymax, flags11, ymax]
		oplot, time, flags11, psym=10
		polyfill, time, flags11

		; Shade limb angle 
		flags12 = flags2 * (ymax-ymin) + ymin
		flags12 = [ymin, flags12, ymin]
		oplot, time, flags12, psym=10, linestyle=2
		polyfill, time, flags12, /line_fill, orientation=0

		; Shade SAA
		;;;flags13 = flags3 * (ymax-ymin) + ymin
		;;;flags13 = [ymin, flags13, ymin]
		;;;oplot, time, flags13, psym=10, linestyle=2

		; Shade burst 
		flags15 = flags5 * (ymax-ymin) + ymin
		flags15 = [ymin, flags15, ymin]
		oplot, time, flags15, psym=10, linestyle=2
		polyfill, time, flags15, /line_fill, orientation=45

 		; Shade jitter
		flags17 = flags7 * (ymax-ymin) + ymin
		flags17 = [ymin, flags17, ymin]
		oplot, time, flags17, psym=10, linestyle=2
		polyfill, time, flags17, /line_fill, orientation=135
	endfor

	; Draw legend
	plot,[0,1],xstyle=7,ystyle=7,/nodata,position=[710-15,5,710+15,25],$
		/noerase,title=" ",xtitle=" ",ytitle=" ",xrange=[0,1],$
		yrange=[0,1],/DEVICE
	polyfill,[0,1,1,0],[0.8,0.8,1,1]
	xyouts,710+20,10,'Day',charsize=1,color=0,/DEVICE

	plot,[0,1],xstyle=7,ystyle=7,/nodata,position=[790-15,5,790+15,25],$
		/noerase,title=" ",xtitle=" ",ytitle=" ",xrange=[0,1],$
		yrange=[0,1],/DEVICE
	polyfill,[0,1,1,0],[0,0,1,1],/line_fill,orientation=0
	oplot,[0,1,1,0,0],[0,0,1,1,0],psym=10
	xyouts,790+20,10,'Limb',charsize=1,color=0,/DEVICE

	plot,[0,1],xstyle=7,ystyle=7,/nodata,position=[870-15,5,870+15,25],$
		/noerase,title=" ",xtitle=" ",ytitle=" ",xrange=[0,1],$
		yrange=[0,1],/DEVICE
	polyfill,[0,1,1,0],[0,0,1,1],/line_fill,orientation=45
	oplot,[0,1,1,0,0],[0,0,1,1,0],psym=10
	xyouts,870+20,10,'Burst',charsize=1,color=0,/DEVICE

	plot,[0,1],xstyle=7,ystyle=7,/nodata,position=[950-15,5,950+15,25],$
		/noerase,title=" ",xtitle=" ",ytitle=" ",xrange=[0,1],$
		yrange=[0,1],/DEVICE
	polyfill,[0,1,1,0],[0,0,1,1],/line_fill,orientation=135
	oplot,[0,1,1,0,0],[0,0,1,1,0],psym=10
	xyouts,950+20,10,'Jitter',charsize=1,color=0,/DEVICE

	xyouts,835,27,'Screenings :',charsize=.9,color=0,/DEVICE,alignment=.5
	xyouts,20,16,'RAW file written at '+pdate,charsize=0.90,color=0,$
		/DEVICE
	xyouts,925,495,'DATEOBS: '+dateobs,charsize=.9,color=0,$
		/DEVICE,alignment=.5

	; Create a GIF/JPEG file: 
	ver = float(!version.release)
	if (ver ge 5.4) then begin
		xyouts,20,6,'JPG file written at '+!stime,charsize=0.90,$
			color=0,/DEVICE
		write_jpeg,rootname+'lin.jpg',TVRD()
	endif else begin
		xyouts,20,6,'GIF file written at '+!stime,charsize=0.90,$
			color=0,/DEVICE
		write_gif,rootname+'lin.gif',TVRD()
	endelse
return
end
