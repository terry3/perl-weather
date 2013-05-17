#!/usr/bin/perl
use 5.010;
use strict;
use LWP;
use XML::Parser::Lite;
use Data::Dumper;

# 调用方法如下：
#输入参数：theCityName = 城市中文名称(国外城市可用英文)或城市代码(不输入默认为上海市)，如：上海 或 58367，如有城市名称重复请使用城市代码查询(可通过 getSupportCity 或 getSupportDataSet 获得)；返回数据： 一个一维数组 String(22)，共有23个元素。
# String(0) 到 String(4)：省份，城市，城市代码，城市图片名称，最后更新时间。
# String(5) 到 String(11)：当天的 气温，概况，风向和风力，天气趋势开始图片名称(以下称：图标一)，天气趋势结束图片名称(以下称：图标二)，现在的天气实况，天气和生活指数。
# String(12) 到 String(16)：第二天的 气温，概况，风向和风力，图标一，图标二。
# String(17) 到 String(21)：第三天的 气温，概况，风向和风力，图标一，图标二。
# String(22) 被查询的城市或地区的介绍

my $weather_url = "http://www.webxml.com.cn/WebServices/WeatherWebService.asmx/getWeatherbyCityName";

die "Input the city name." if scalar @ARGV == 0;
my $city_name = shift @ARGV;    # 城市名称
my $city_code = &get_city_code($city_name); # 城市代码

my $browser = LWP::UserAgent->new();
my $weather_result = $browser->post($weather_url, ["theCityName" => $city_code]);

#say $weather_result->content;

my $string_toggle = 0;
my @response;

my $p1 = new XML::Parser::Lite;
$p1->setHandlers(
  Start => sub {
#    say Dumper(@_);
    shift @_;
    my $string = shift @_;
    if($string =~ /string/){
      $string_toggle = 1;
    }
    else{
      $string_toggle = 0;
    }
  },
  Char => sub {
    shift;
    my $char = shift @_;
    push @response, $char if ($string_toggle && !($char =~ /^\s*?$/));
  },
    );
$p1->parse($weather_result->content);

basic_info(\@response);
today_weather(\@response);
other_day_weather(\@response, 12);
other_day_weather(\@response, 17);
city_description(\@response);

sub city_description{
  my $city_des = shift @_;
  say '    ' . $$city_des[22];
}

sub get_city_code{
  my $city_name = shift @_;
  my $ret;
  open CITY_NAME, "city-code.data" or dir $!;
  while(<CITY_NAME>){
    if(/$city_name..(\d*)./){
      $ret = $1;
      last;
    }
  }
  close CITY_NAME;
  $ret;
}

sub basic_info{
  my $tmp = shift @_;
  say "城市：$$tmp[1] 发布日期：$$tmp[4]";
}

sub other_day_weather{
  my ($tmp, $index) = @_;
  printf "%-20s %-12s %-10s\n", $$tmp[$index + 1], $$tmp[$index],  $$tmp[$index + 2];
}

sub today_weather{
  my $tmp = shift @_;
  say "$$tmp[10]";
  say "气温区间：$$tmp[5]";
}
