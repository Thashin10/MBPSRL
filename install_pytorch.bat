@echo off
echo Installing PyTorch in mbpsrl environment...
echo.

call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl

echo Installing PyTorch 1.7.1 (CPU version for Python 3.7)...
pip install torch==1.7.1+cpu torchvision==0.8.2+cpu -f https://download.pytorch.org/whl/torch_stable.html

echo.
echo Installation complete!
echo.
pause
