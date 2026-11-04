This is the readme file for data and code to replicate 
Forward Difference-in-Differences by Kathleen T. Li published in Marketing Science 

Since the dataset used in the paper is proprietary, 
I release MATLAB and R code to use the Forward DID method to estimate treatment effects and conduct inference 
using a publicly available dataset. 

Data:
1) GDP.cvs 
Excel dataset of publicly available dataset used in 
Hsiao, Ching and Wan (2012) A panel data approach for program evaluation: 
measuring the benefits of political and economic integration of Hong Kong with mainland China.
Journal of Applied Econometrics, 27(5), 705-740.
The first column (Hong Kong) is the treatment unit and all other columns are the control units. 

MATLAB code:
2) FDID_Matlab.m
MATLAB code that use the Forward DID method to estimate treatment effects, conduct inference, and create figures 
3) FDID_newR2.m 
subroutine used by FDID_Matlab.m 

R code:
4) FDID_R.r
R code that use the Forward DID method to estimate treatment effects, conduct inference, and create figures 
5) Fun_FDID.r
R function used by FDID_R.r


------------------------------------------------------------------------

This next section contains the sample out from running the MATLAB and R code. 

MATLAB Sample output: 
Number_controls_selected_by_FDID = 9

ATT_FDID =  0.025405
ATT_FDID_per = 53.843
R2_forward_DID = 0.84278

ATT_std_FDID = 5.4941
p_value_forward_DID =  3.9274e-08
p_value_fDID_one_sided =  1.9637e-08

CI_95_FDID_width = [0.016342,  0.034468] with a width = 0.018126

The code also computes conventional DID ATT estimation results. 
It reports the following DID ATT estimation results:

ATT_DID =  0.031721
ATT_DID_percentage = 77.62

R2_DID =  0.50465
ATT_std_DID =  3.8647
p_value_DID = 0.00011122
p_value_one_sided =  5.5609e-05

CI_95_DID_width = 0.015634     0.047809     0.032175


Sample R output: 
> FDID$num_c
[1] 9
> FDID$select[1:FDID$num_c]
[1] 19 18 22 14 11 10 20 13 21
> FDID$ATT_FDID
[1] 0.02540494
> FDID$ATT_FDID_per
[1] 53.84307
> FDID$R2_FDID
[1] 0.8427835

