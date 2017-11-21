Occlusion   Filling

Team   members
Hugh   Matsubara
Wen   De   Zhou   (1001713274)
Problem
When   we   are   looking   around   our   world,   we   many   great   things   around   us.   However   some   of   the   things   are
blocked   by   others,   making   us   unable   to   fully   enjoy   all   the   great   things   around   us.   We   propose   a   solution that   can   solve   this   problem,   were   as   everyone   in   the   near   distant   future   has   access   to   intelligence   eye   wear (i.e.   Google   Glass)   that   can   keeps   track   of   what   you   are   seeing   (before   time   =   now)   and   what   others   are seeing,   we   can   use   this   as   the   database   to   generate/fill   in   the   parts   where   the   object   is   being   occluded, allowing   us   to   have   the   ability   to   see   through   objects..
Our   solution   involves   recognize   occlusion   using   segmentation.   Figure   out   what   parts   of   an   image   are being   occluded   by   matching   keypoints   in   images   taken   from   multiple   angles.   Using   pose   estimates,   we attempt   to   fill   in   the   occluded   image.
Procedure
1. Generate   data   set   by   taking   pictures   of   objects   at   different   angles   wherein   some   parts   are   occluded
(i.e.   by   trees   and/or   buildings).   (Done   by   Wen   De)
2. Use   segmentation   to   detect   objects   in   the   source   image   (the   image   with   object   that   are   occluded)
and   the   data   image(s)   (the   image(s)   where   the   object   is   not   occluded).   (Done   by   Hugh)
3. Use   pose   estimation   to   figure   out   camera   positions   relative   to   each   shot.   (Done   by   Wen   De)
4. Detect   key   points   between   those   images   using   SIFT   (and/or   other   techniques),   and   use   those   key
points   to   determine   the   transformation/relation   between   the   images.   (Done   by   Hugh)
5. Use   the   transformation   and   segmentation   found   to   transform   the   data   image(s),   and   use   them   to
reconstruct   the   object   that   is   being   occluded   in   the   source   image.   (Done   by   Wen   De)
6. Adjust   and   blend   parts   of   the   source   image   that   has   been   filled   in   so   that   the   filled   out   parts
closely   match   the   rest   of   the   image   even   if   the   images   used   have   different   photometry.   (Done   by Hugh)
Implementation
This   project   is   going   to   be   done   with   a   group   of   2.   Images   used   in   this   project   is   going   to   be   taken   by   us.
This   assignment   is   going   to   be   written   in   MATLAB,   with   the   imaging   libraries   packaged   inside.   Since   we have   yet   to   learn   the   full   scope   of   this   course   (recognition   and   parts   of   geometry)   we   will   not   be   able   to list   the   full   libraries   we   will   be   using   to   implement   this   project.   This   project   is   completely   original,   with no   prior   on   the   market,   thus   we   will   be   trying   our   best   to   implement   and   explore   additional   options.
Inspired   From
Real-Time   Monocular   Segmentation   and   Pose   Tracking   of   Multiple   Objects
https://www.youtube.com/watch?v=-nFkNPqf1LU
Note:   this   is   done   with   prior   shape   knowledge,   but   we   do   not   use   that      in   our   project.
