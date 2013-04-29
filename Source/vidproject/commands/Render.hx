package vidproject.commands;

using Detox;
using StringTools;
import sys.FileSystem;
import Sys.println;

class Render
{
    var xml:dtx.DOMCollection;

    public function new(project:String, renderType:RenderType)
    {
        var str = sys.io.File.getContent(project);
        xml = str.parse();
        var parts = getSegmentsToExport();

        var projectPath = project.split("/");
        var filename = projectPath.pop();
        var extension = switch(renderType)
        {
            case MP3: "MP3";
            case DVD: "VOB";
        }
        var exportDir = projectPath.join("/") + "/Exports/" + extension.toUpperCase();

        if (!FileSystem.exists(exportDir)) FileSystem.createDirectory(exportDir);
        for (part in parts)
        {
            var result = renderPortion(filename, '$exportDir/${part.segment}.$extension', part.startPoint, part.endPoint, renderType);

            if (!result)
            {
                println("Failed to render... Exiting early");
            }
        }
    }

    // Given the project Xml, find the track by the given name
    function findTrackByName(name:String)
    {
        // Search for child <kdenlivedoc> (should be last child, should only be one of them)
        // This is the data that isn't important to rendering, but is to the project - tracknames, project imports etc.
        // Search for child <tracksinfo> (should only be one of them)
        var trackInfoList = xml.find('kdenlivedoc tracksinfo');

        // Get list of children <trackinfo> (should be about 6 of them in our template)
        // These correspond to the tracks in our kdenlive project.  The first element is the bottom track,
        // The second element is the second from the bottom, the final element is the top track etc.
        var index = 0;
        for (trackinfo in trackInfoList.children())
        {
            // Get the one who has the attribute trackname="$name"
            // Get it's index.  (First child=0, second child=1, third=2 etc)
            if (trackinfo.attr('trackname') == name) break;
            index++;
        }

        // Go back to the MLT object, and select all the <playlist> elements, then get our one by the index.
        // In the MLT tracks, a "black_track" is added, so our MLT-index will be one higher
        var mltPlaylists = xml.find('playlist');
        var ourplaylist = mltPlaylists.getNode(index + 1);


        // Return this playlist.
        return ourplaylist;
    }

    function getSegmentsToExport()
    {
        var playlist = findTrackByName("Break");

        var partsToExport = new Array<ExportDefinition>();

        var currentFrame = 0; // Should this be 1?  Will have to test
        var currentSegment = 1;

        for (child in playlist.children())
        {
            switch (child.tagName())
            {
                case "entry":
                    // If it's <entry>, then there's something in this track, so we do not export this segment.
                    // get the duration, based on the in and out points, inclusive (+1)
                    var duration = Std.parseInt(child.attr("out")) - Std.parseInt(child.attr("in")) + 1;
                    currentFrame = currentFrame + duration;
                case "blank":
                    // If it's <blank>, then there's nothing in this track, so we do export this segment
                    
                    var startPoint = currentFrame;
                    var duration = Std.parseInt(child.attr("length"));
                    currentFrame = currentFrame + duration;
                    var endPoint = currentFrame;
                    // print "Export Part%s.vob from %s to %s" % (currentSegment, startPoint, endPoint)
                    //trace ("~/Scripts/kdenlive/renderExcerpt.sh '02 Kdenlive/Lectures.kdenlive' '03 Exports/Part%s.vob' %s %s") % (currentSegment, startPoint, endPoint)

                    partsToExport.push({
                        segment: "Part" + currentSegment,
                        startPoint: startPoint,
                        endPoint: endPoint
                    });

                    currentSegment++;

            }
        }

        return partsToExport;
    }

    function renderPortion(source, target, inPoint:Int, outPoint:Int, renderType:RenderType)
    {
        var renderer = "/usr/bin/kdenlive_render";
        var melt = "/usr/bin/melt";
        var parameterString = switch (renderType)
        {
            case MP3: 'in=$inPoint out=$outPoint $melt hdv_1080_50i avformat - $source $target f=mp3 acodec=libmp3lame ab=128k ar=44100 threads=8 real_time=-1';
            case DVD: 'in=0 out=100 $melt hdv_1080_50i avformat - consumer:$source $target f=dvd vcodec=mpeg2video acodec=ac3 vb=5000k maxrate=8000k minrate=0 bufsize=1835008 packetsize=2048 muxrate=10080000 ab=192k ar=48000 s=720x576 g=15 me_range=63 trellis=1 mlt_profile=dv_pal_wide pass=1 threads=8 real_time=-1';
        }
        var parameters = parameterString.split(" ");

        println("About to run render command: ");
        println('  Input:');
        println('    $source, $target, $inPoint, $outPoint');
        println('  Command:');
        println('    $renderer ${parameters.join(" ")}');

        var result = Sys.command(renderer, parameters);

        if (result == 0)
        {
            return true;
        } 
        else 
        {
            println('File $target may not have rendered correctly... the render process had a return other than 0');
            return false;
        }
    }
}

typedef ExportDefinition = {
    segment:String,
    startPoint:Int,
    endPoint:Int
}

enum RenderType {
    MP3;
    DVD;
}