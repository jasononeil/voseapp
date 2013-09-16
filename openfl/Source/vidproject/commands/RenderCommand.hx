package vidproject.commands;

using Detox;
using StringTools;
import vidproject.commands.Command;
import haxe.PosInfos;
import dtx.DOMNode;
import haxe.ds.StringMap;
import sys.FileSystem;
import sys.io.File;
using tink.core.types.Outcome;

class RenderCommand extends Command
{
    var parts:Array<ExportDefinition>;
    var exportDir:String;
    var extension:String;
    var projectExportFilePath:String;
    var renderType:RenderType;

    public function new(project:String, renderType:RenderType)
    {
        super();

        try {
            this.renderType = renderType;

            // Get the project file
            var str = File.getContent(project);
            var projectXml = str.parse();

            // Read the Xml to get segments to export
            parts = getSegmentsToExport(projectXml);

            // Figure out the export path
            var projectPath = project.split("/");
            var projectFileName = projectPath.pop();
            extension = switch(renderType) {
                case MP4: "MP4";
                case MP3: "MP3";
                case DVD: "VOB";
            }

            // Make sure we're not using proxy clips, and save a temp version of the project
            var readyToRenderXml = prepareXmlForExport(projectXml);
            var projectExportFileName = '.$projectFileName.${Date.now().getTime()}.mlt';
            projectExportFilePath = projectPath.join("/") + "/" + projectExportFileName;
            File.saveContent(projectExportFilePath, readyToRenderXml.html());

            // Create the export DIR if it doesn't exist
            exportDir = projectPath.join("/") + "/Exports/" + extension.toUpperCase();
            if (!FileSystem.exists(exportDir)) FileSystem.createDirectory(exportDir);
            
            updateStatus( SReady );
        } catch (e:Dynamic) {
            updateStatus( SInvalid('Failed to setup Render command: $e') );
        }
    }

    override public function execute() 
    {
        // Render each part, if it doesn't exist
        var showRmRfMessage = false;
        for (part in parts)
        {
            var partFileName = '$exportDir/${part.segment}.$extension';
            if (!FileSystem.exists(partFileName))
            {
                var result = renderPortion(projectExportFilePath, partFileName, part.startPoint, part.endPoint, renderType);

                if (!result)
                {
                    failWithMsg("Failed to render... Exiting early");
                }
            }
            else 
            {
                failWithMsg('File $partFileName already exists, skipping rendering.  ');
            }

        }
        log( 'Rendered ${parts.length} successfully' );
        updateStatus( SCompleted );
    }

    function failWithMsg(msg:String, ?p:PosInfos) {
        log (msg,p);
        log ('  Run `rm -rf $exportDir/*` to delete all existing renders.', p);
        updateStatus( SError(msg) );
    }

    // Given the project Xml, find the track by the given name
    function findTrackByName(xml:dtx.DOMCollection, name:String)
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

    function getSegmentsToExport(xml:dtx.DOMCollection)
    {
        var playlist = findTrackByName(xml, "Break");

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
                    //log ("~/Scripts/kdenlive/renderExcerpt.sh '02 Kdenlive/Lectures.kdenlive' '03 Exports/Part%s.vob' %s %s") % (currentSegment, startPoint, endPoint)

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

    function prepareXmlForExport(inXml:dtx.DOMCollection)
    {
        var outXml = inXml.clone();
        
        // Get the Kdenlive clips, make a Map of proxyPath=>clipPath
        var proxyMap = new StringMap();
        var clips = outXml.find("kdenlive_producer");
        for (c in clips)
        {
            var origClip = c.attr("resource");
            var proxyClip = c.attr("proxy");
            if (proxyClip != "-" && proxyClip != "")
            {
                proxyMap.set(proxyClip, origClip);
            }
        }

        // Get the MLT producers, swap in real clips where proxies are used
        var producers = outXml.find("producer property[name=resource]");
        var mlt = outXml.filter(function (n) return n.tagName() == "mlt").getNode();
        var basePath = mlt.attr("root") + "/";
        var swapCount = 0;
        for (p in producers)
        {
            var proxyPath = basePath + p.text();
            if (proxyMap.exists(proxyPath))
            {
                var realPath = proxyMap.get(proxyPath);
                p.setText(realPath);
                swapCount++;
            }
        }
        log ('Swapped out $swapCount proxy clips');

        return outXml;
    }

    function renderPortion(source, target, inPoint:Int, outPoint:Int, renderType:RenderType)
    {
        // All the parts of our command call
        var renderer = "/usr/bin/kdenlive_render";
        var inParam = 'in=$inPoint';
        var outParam = 'out=$outPoint';
        var melt = "/usr/bin/melt";
        var profile = "hdv_1080_50i";
        var renderModule = "avformat";
        var player = "-";
        var argsString = switch (renderType)
        {
            case MP4: 'f=mp4 hq=1 acodec=aac ab=384k ar=48000 pix_fmt=yuv420p vcodec=libx264 minrate=0 vb=2000k g=250 bf=3 b_strategy=1 subcmp=2 cmp=2 coder=1 flags=+loop flags2=dcd8x8 qmax=51 subq=7 qmin=10 qcomp=0.6 qdiff=4 trellis=1 aspect=@16/9 pass=1 threads=8 real_time=-1 s=640x480';
            case MP3: 'f=mp3 acodec=libmp3lame ab=39k ar=22050 ac=1 threads=8 real_time=-1';
            case DVD: 'f=dvd vcodec=mpeg2video acodec=ac3 vb=5000k maxrate=8000k minrate=0 bufsize=1835008 packetsize=2048 muxrate=10080000 ab=192k ar=48000 s=720x576 g=15 me_range=63 trellis=1 mlt_profile=dv_pal_wide pass=1 threads=8 real_time=-1';
        }

        // Stitch it all together as a parameter array
        var parameters = [];
        parameters.push(inParam);
        parameters.push(outParam);
        parameters.push(melt);
        parameters.push(profile);
        parameters.push(renderModule);
        parameters.push(player);
        parameters.push('consumer:$source');
        parameters.push('$target');
        for (a in argsString.split(" "))
        {
            parameters.push(a);
        }

        // Print our info for debugging purposes
        log ("About to run render command: ");
        log ('  Input:');
        log ('    Source: $source');
        log ('    Target: $target');
        log ('    $inPoint - $outPoint');
        log ('  Command:');
        log ('    $renderer ${parameters.join(" ")}');

        // Run the command, return the result
        var result = Sys.command(renderer, parameters);
        if (result == 0)
        {
            return true;
        } 
        else 
        {
            log ('File $target may not have rendered correctly... the render process had a return other than 0');
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
    MP4;
    MP3;
    DVD;
}
