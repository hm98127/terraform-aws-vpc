resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-101"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "101subnet-1"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "101subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-101-igw"
  }
}

# -- 비용 발생 구간 주석 처리 ( NAT 게이트웨이 경우 시간단위로 과금됨 Free tier X ) 
#resource "aws_eip" "nat" {
#  vpc   = true
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
# resource "aws_nat_gateway" "nat_gateway_1" {
#  allocation_id = aws_eip.nat.id
#
#  # Private subnet이 아니라 public subnet을 연결하셔야 합니다.
#  subnet_id = aws_subnet.public_subnet.id
#
#  tags = {
#    Name = "terraform-NATGW"
#  }
#}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id 

# 아래 
# route {
#  cidr_block = "0.0.0.0/0"
#  gateway_id = aws_internet_gateway.main.id
# }

  tags = {
    Name = "terraform-101-rt-public"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-101-rt-private"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

# 라우터 룰 정하는 방법 2가지
# 1. 외부 리소스를 따로 테라폼 코드로 작성
# 확장성을 생각하면 이방법을 쓰는 것이 잘만든 코드인 것 ( 유연한 코드)
resource "aws_route" "public_subnet" {
  route_table_id              = aws_route_table.route_table_public.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}

resource "aws_route" "private_subnet" {
  route_table_id              = aws_route_table.route_table_private.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gateway.id
}

# 2. Inner rule -  Ingress 연결 
#  위 resource public 에 다음 절 추가 위에 ㅊ주석으로 처리해주겟음 *2개 표시됨
# route {
#  cidr_block = "10.0.1.0/24"
#  gateway_id = aws_internet_gateway.igw.id
# } 
#
#
