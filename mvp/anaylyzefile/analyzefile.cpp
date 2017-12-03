#include <cstdio>
#include <string>

extern "C"
{
#include <libavformat/avformat.h>
}

#include "swype_detect.h"


int main(int argc, char *argv[])
{
    if(argc<=2)
        return 1;

    av_register_all();
    avcodec_register_all();

    AVFormatContext *formatctx=NULL;

    int rc=avformat_open_input(&formatctx, argv[1], NULL, NULL);
    if(rc<0)
    {
        fprintf(stderr, "avformat_open_input failed\n");
        return 2;
    }

    fprintf(stderr, "calling avformat_find_stream_info\n");
    rc=avformat_find_stream_info(formatctx, NULL);
    if(rc<0)
    {
        fprintf(stderr, "failed rc=%d\n", rc);
        return 2;
    }

    int videoStreamIndex=-1;
    for(unsigned int index=0; index<formatctx->nb_streams; ++index)
    {
        if(formatctx->streams[index]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO)
            videoStreamIndex=index;
    }
    if(videoStreamIndex==-1)
    {
        fprintf(stderr, "No video stream found\n");
        return 2;
    }

    AVCodec *codec=avcodec_find_decoder(formatctx->streams[videoStreamIndex]->codecpar->codec_id);
    if(!codec)
    {
        fprintf(stderr, "no codec found\n");
        return 2;
    }

    AVCodecContext *codecctx=avcodec_alloc_context3(codec);
    if(!codecctx)
    {
        fprintf(stderr, "avcodec_alloc_context3 failed\n");
        return 2;
    }

    avcodec_open2(codecctx, codec, NULL);

    rc=avcodec_parameters_to_context(codecctx, formatctx->streams[videoStreamIndex]->codecpar);
    if(rc<0)
    {
        fprintf(stderr, "avcodec_parameters_to_context failed %d\n", rc);
        return 2;
    }


    const AVBitStreamFilter *bsf=av_bsf_get_by_name("h264_mp4toannexb");
    if(!bsf)
    {
        fprintf(stderr, "failed to create bitstream filter\n");
        return 2;
    }

    AVBSFContext *bsfctx=NULL;
    if(av_bsf_alloc(bsf, &bsfctx)<0)
    {
        fprintf(stderr, "failed to create bitstream filter context\n");
        return 2;
    }

    avcodec_parameters_copy(bsfctx->par_in, formatctx->streams[videoStreamIndex]->codecpar);
//    bsfctx->time_base_in=formatctx->time_base;

    if(av_bsf_init(bsfctx)<0)
    {
        fprintf(stderr, "failed to initialize bitstream filter\n");
        return 2;
    }

    int fps=formatctx->streams[videoStreamIndex]->avg_frame_rate.num/formatctx->streams[videoStreamIndex]->avg_frame_rate.den;

    std::string swype=argv[2];
    SwypeDetect detector;
    detector.init(fps, swype);

    AVFrame *frame=av_frame_alloc();
    while(true)
    {
        AVPacket packet;
        int rc;

        av_init_packet(&packet);

        if((rc=av_read_frame(formatctx, &packet))!=0)
        {
            fprintf(stderr, "Failed to read packed %d\n", rc);
            break;
        }
        fprintf(stderr, "Input packet: %d %d\n", packet.stream_index, packet.size);

        if(packet.stream_index==videoStreamIndex)
        {
            AVPacket *newpacket=av_packet_alloc();

            av_bsf_send_packet(bsfctx, &packet);
            while((rc=av_bsf_receive_packet(bsfctx, newpacket))==0)
            {
                avcodec_send_packet(codecctx, newpacket);

                while((rc=avcodec_receive_frame(codecctx, frame))==0)
                {
                    int state=-1, index=-1, x=-1, y=-1;
                    int debug=-1;

                    detector.processFrame_new(frame->data[0], frame->width, frame->height, state, index, x, y, debug);
                    fprintf(stderr, "S=%d index=%d x=%d y=%d debug=%d\n", state, index, x, y, debug);
                }
                if(rc==AVERROR_EOF)
                    break;

                av_packet_unref(newpacket);
            }

            if(rc!=AVERROR(EAGAIN))
            {
                
            }

            av_packet_free(&newpacket);
        }

        av_packet_unref(&packet);
    }

    return 0;
}
