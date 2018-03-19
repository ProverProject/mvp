function [S, call] = processFrame(frame1,frame2, width, height, fps, swype, S, call, count,Swype_KoordX, Swype_KoordY, Swype_Numbers, deltaXX, deltaYY, count_num, count_direction,count_sum)
call=call+1;
usfac = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ����������� ��������� ��������
if S==0
    buf1ft=dfft(frame1);
    buf2ft=dfft(frame2);
    [output] = Phase_Cor(fft2(buf1ft),fft2(buf2ft),usfac);
    [deltaX, deltaY, deltaXX, deltaYY, K, Mean_Alfa, Direction]=Delta_calculation(output,call, deltaXX, deltaYY);
    
    if ((abs(deltaX))>3)||((abs(deltaY))>3)
        [flag_R, S] = CircleDetection(deltaXX, deltaYY, buf1ft, S);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �������� ����� swype
if S==1
    if swype==0
        %%%%%%%%%  ���� ����� ����
        [koord_x, koord_y, Numbers] = Koord_Swipe_points(vidHeight,vidWidth);
        
        
        if ((abs(deltaX))>3)||((abs(deltaY))>3)
            count_direction=count_direction+1;
            Direction_S(count_direction)=Direction;
            count_sum=count_sum+1;
        end
        
        
        if (count_sum>3)&&(Direction_S(count_direction)==Direction_S(count_direction-1))&&(Direction_S(count_direction-1)==Direction_S(count_direction-2))
            % ������ �������
            count_num=count_num+1;
            
            % Swype_Numbers==0 ����� �� ������� ������
            if Swype_Numbers(count_num-1)==0
                Swype_Numbers(count_num)=Numbers(1);
                Swype_KoordX(count_num)=koord_x(1);
                Swype_KoordY(count_num)=koord_y(1);
            else
                [Swype_Numbers, Swype_KoordX, Swype_KoordY] = Swype_Data(Swype_Numbers, Swype_KoordX, Swype_KoordY, count_direction,Direction_S,count_num, Numbers,koord_x, koord_y);
            end
            count_sum=0;
        end
        
        if count_sum>3
            count_sum=0;
        end
        Direction_S
        Swype_Numbers
        
        
        if lenght(Swype_Numbers)==9
            S=3;
        end
        
    else
        %%%%%%%%%  ���� swype ����
        S=2;
        swype_Numbers=importdata('swype_Numbers.txt');
        %%%%%%%%%  ���������� ��� ������������
        
        
        �*��@param�x,�y�[out]�����������state==2,��������������������������������������
        �������� ������������ ����������, ��� ���� � ������ ����������� ������ ���������� S2 (i) � ���������� ����� ���������� ���
        ������������;
        
        
        ���� ���������� � ���� ����� swype "�������" � ���� ������ �����, �� ���, ������� �� �������, �� ���������� ������� �������� �
        ��������� S0, ��� ���� ���� swype-��� �� ��� ����� ��� ������������� ���������, ��� ����� ���� ��������;
        
        
        ���� swype-��� �� ������ ��������� � ������� �������, ������� 2*N ������, ��� N - ���������� ������ � swype-����, �� ������� �
        ��������� S0, ��� ���� ���� swype-��� �� ��� ����� ��� ������������� ���������, ��� ����� ���� ��������. �����! ����� �������
        ������������ ������ ������ �� ��������� ��� ������������� fps. � �������������, ���������� ������� ����� ��������� �������;
        ���� ������������� swype-���� ������� ���������, ������� � ��������� S3.
        
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end